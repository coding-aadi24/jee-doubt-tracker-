import { Request, Response } from 'express';
import fs from 'fs/promises';
import path from 'path';
import { PrismaClient } from '@prisma/client';
import { GoogleDriveService } from '../services/googleDriveService';
import { PdfService } from '../services/pdfService';
import { config } from '../config/index';

const prisma = new PrismaClient();

// In-memory fallback store if database is not reachable during local dev testing
interface FallbackDriveUploadRecord {
  id: string;
  className: string;
  subject: string;
  chapter: string;
  fileName: string;
  driveFileId: string;
  userName: string | null;
  userEmail: string | null;
  fileSizeBytes: number | null;
  createdAt: string;
}

let fallbackUploads: FallbackDriveUploadRecord[] = [];

export class UploadController {
  /**
   * POST /api/v1/upload-to-drive
   * Handles multipart/form-data upload.
   */
  static async uploadToDrive(req: Request, res: Response): Promise<void> {
    const file = req.file;
    const { className, subject, chapter, userName, userEmail, pageNumber, forceAppend } = req.body;

    if (!file) {
      res.status(400).json({ success: false, error: 'PDF file is required in request field "pdfFile"' });
      return;
    }

    if (!className || !subject || !chapter) {
      await fs.unlink(file.path).catch(() => {});
      res.status(400).json({ success: false, error: 'className, subject, and chapter are required.' });
      return;
    }

    try {
      const isForceAppend = String(forceAppend) === 'true';

      // 1. Duplicate Check in Database
      let existingRecord: any = null;
      try {
        existingRecord = await prisma.driveUpload.findFirst({
          where: {
            className: String(className),
            subject: String(subject),
            chapter: String(chapter),
          },
        });
      } catch (_) {
        existingRecord = fallbackUploads.find(
          (u) => u.className === String(className) && u.subject === String(subject) && u.chapter === String(chapter)
        );
      }

      // If Doubt PDF already exists and forceAppend is not set -> Return 409 Conflict with popup prompt payload
      if (existingRecord && !isForceAppend) {
        await fs.unlink(file.path).catch(() => {});
        res.status(409).json({
          success: false,
          exists: true,
          message: `A Doubt PDF for "${className} -> ${subject} -> ${chapter}" already exists!`,
          existingRecord,
        });
        return;
      }

      // 2. Prepare target PDF (Extract single page if pageNumber specified)
      let uploadFilePath = file.path;
      const safeChapterName = String(chapter).replace(/[^a-zA-Z0-9_-]/g, '_');
      const safeClassName = String(className).replace(/[^a-zA-Z0-9_-]/g, '_');
      const safeSubject = String(subject).replace(/[^a-zA-Z0-9_-]/g, '_');
      const targetFileName = `${safeClassName}_${safeSubject}_${safeChapterName}.pdf`;

      if (pageNumber) {
        const pageNum = parseInt(String(pageNumber), 10);
        if (!isNaN(pageNum) && pageNum > 0) {
          const extractedPath = path.join(config.storagePath, 'extracted', `extracted_${Date.now()}.pdf`);
          await fs.mkdir(path.dirname(extractedPath), { recursive: true });

          // Load base existing PDF from local storage or Google Drive if available
          const existingLocalPath = path.join(config.storagePath, targetFileName);
          let hasBasePdf = false;
          try {
            await fs.access(existingLocalPath);
            await fs.copyFile(existingLocalPath, extractedPath);
            hasBasePdf = true;
          } catch (_) {}

          if (!hasBasePdf && existingRecord?.driveFileId) {
            try {
              const driveBuf = await GoogleDriveService.downloadFile(existingRecord.driveFileId);
              if (driveBuf && driveBuf.slice(0, 4).toString() === '%PDF') {
                await fs.writeFile(extractedPath, driveBuf);
                hasBasePdf = true;
              }
            } catch (_) {}
          }

          console.log(`📄 Appending Page ${pageNum} from "${file.originalname}" into "${targetFileName}" (Existing Base: ${hasBasePdf})...`);
          await PdfService.extractAndAppendPage(file.path, pageNum, extractedPath);
          uploadFilePath = extractedPath;
        }
      }

      // 3. Delete old file from Google Drive if replacing existing record
      if (existingRecord?.driveFileId) {
        console.log(`🗑️ Deleting old file ${existingRecord.driveFileId} from Google Drive...`);
        await GoogleDriveService.deleteFile(existingRecord.driveFileId).catch(() => {});
      }

      console.log(`🚀 [Traffic Controller] Uploading PDF "${targetFileName}" for ${className} -> ${subject} -> ${chapter}`);

      // 4. Upload new combined PDF to Google Drive
      const { fileId: driveFileId, isMock } = await GoogleDriveService.uploadFile(
        uploadFilePath,
        targetFileName,
        'application/pdf'
      );

      // 5. Purge all old duplicate files with targetFileName from Google Drive (except new driveFileId)
      await GoogleDriveService.deleteFilesByName(targetFileName, driveFileId);

      // Save static local server copy for fast HTTP streaming
      const staticServerPath = path.join(config.storagePath, targetFileName);
      await fs.copyFile(uploadFilePath, staticServerPath).catch((err) => {
        console.warn(`⚠️ Failed to save static server copy: ${err.message}`);
      });

      // Clean up extracted temp file if different from uploaded source
      if (uploadFilePath !== file.path) {
        await fs.unlink(uploadFilePath).catch(() => {});
      }

      // 4. Save or Update PostgreSQL DB Record
      let savedRecord: any;
      try {
        if (existingRecord?.id) {
          savedRecord = await prisma.driveUpload.update({
            where: { id: existingRecord.id },
            data: {
              driveFileId,
              fileSizeBytes: file.size,
              userName: userName ? String(userName) : existingRecord.userName,
              userEmail: userEmail ? String(userEmail) : existingRecord.userEmail,
            },
          });
        } else {
          savedRecord = await prisma.driveUpload.create({
            data: {
              className: String(className),
              subject: String(subject),
              chapter: String(chapter),
              fileName: targetFileName,
              driveFileId,
              userName: userName ? String(userName) : null,
              userEmail: userEmail ? String(userEmail) : null,
              fileSizeBytes: file.size,
            },
          });
        }
        console.log(`💾 Saved Drive File ID (${driveFileId}) in PostgreSQL database (ID: ${savedRecord.id})`);
      } catch (dbError: any) {
        console.warn(`⚠️ Database note: ${dbError.message}. Using in-memory fallback.`);
        savedRecord = {
          id: existingRecord?.id || `upl_${Date.now()}`,
          className: String(className),
          subject: String(subject),
          chapter: String(chapter),
          fileName: targetFileName,
          driveFileId,
          userName: userName ? String(userName) : null,
          userEmail: userEmail ? String(userEmail) : null,
          fileSizeBytes: file.size,
          createdAt: new Date().toISOString(),
        };
        if (!existingRecord) fallbackUploads.push(savedRecord);
      }

      // Clean up original uploaded file
      await fs.unlink(file.path).catch(() => {});

      // 5. Success Response
      res.status(201).json({
        success: true,
        message: existingRecord
          ? `Page appended to existing Doubt PDF for ${chapter}!`
          : `New Doubt PDF created and uploaded to Google Drive for ${chapter}!`,
        driveFileId,
        isMockDriveId: isMock,
        data: savedRecord,
      });
    } catch (error: any) {
      if (file) {
        await fs.unlink(file.path).catch(() => {});
      }
      console.error('❌ Upload Traffic Controller Error:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Internal server error during drive upload process',
      });
    }
  }

  /**
   * Helper to parse Class, Subject, and Chapter metadata from PDF file names.
   */
  static parseMetadataFromFileName(fileName: string): { className: string; subject: string; chapter: string } {
    let className = 'Class 12';
    let subject = 'Mathematics';
    let chapter = 'Chapter 5: Continuity and Differentiability';

    const clean = fileName.replace('.pdf', '');

    if (clean.includes('Class_11')) className = 'Class 11';
    if (clean.includes('Class_12')) className = 'Class 12';

    if (clean.includes('Physics')) {
      subject = 'Physics';
      if (clean.includes('Electric_Charges') || clean.includes('Chapter_1')) {
        chapter = 'Chapter 1: Electric Charges and Fields';
      }
    } else if (clean.includes('Chemistry')) {
      subject = 'Chemistry';
      if (clean.includes('Alcohols') || clean.includes('Chapter_7')) {
        chapter = 'Chapter 7: Alcohols, Phenols and Ethers';
      }
    } else if (clean.includes('Mathematics')) {
      subject = 'Mathematics';
      if (clean.includes('Continuity') || clean.includes('Chapter_5')) {
        chapter = 'Chapter 5: Continuity and Differentiability';
      }
    }

    return { className, subject, chapter };
  }

  /**
   * Helper to synchronize and auto-discover files from Google Drive and local storage
   */
  static async getCombinedUploadRecords(): Promise<any[]> {
    const list = [...fallbackUploads];

    try {
      // 1. Fetch real files from Google Drive API
      const driveFiles = await GoogleDriveService.listFiles();
      for (const df of driveFiles) {
        if (!list.some((r) => r.driveFileId === df.id || r.fileName === df.name)) {
          const meta = UploadController.parseMetadataFromFileName(df.name);
          list.push({
            id: `drive_${df.id}`,
            className: meta.className,
            subject: meta.subject,
            chapter: meta.chapter,
            fileName: df.name,
            driveFileId: df.id,
            userName: 'Google Drive',
            userEmail: null,
            fileSizeBytes: 128609,
            createdAt: new Date().toISOString(),
          });
        }
      }
    } catch (_) {}

    // 2. Local fallback scanning removed to prevent deleted Drive files from resurrecting

    return list;
  }

  /**
   * GET /api/v1/uploads
   * List all drive uploaded files saved in database or discovered in Drive folder / local storage.
   */
  static async listUploads(req: Request, res: Response): Promise<void> {
    try {
      const dbRecords = await prisma.driveUpload.findMany({
        orderBy: { createdAt: 'desc' },
      });

      // Filter DB records to ensure only files that actually exist in Drive are returned (respecting manual deletions)
      if (dbRecords && dbRecords.length > 0) {
        let driveFetchSuccess = true;
        const driveFiles = await GoogleDriveService.listFiles().catch(() => {
          driveFetchSuccess = false;
          return [];
        });
        const localFiles = await fs.readdir(config.storagePath).catch(() => []);

        const validDbRecords = dbRecords.filter((r) => {
          const existsInDrive = driveFiles.some((df) => df.id === r.driveFileId || df.name === r.fileName);
          const existsLocally = localFiles.some((lf) => lf === r.fileName);
          
          if (driveFetchSuccess) {
             // If Drive API worked, treat Google Drive as the absolute source of truth
             return existsInDrive;
          } else {
             // Fallback if Drive API is down
             return existsInDrive || existsLocally;
          }
        });

        if (driveFetchSuccess) {
          // Drive API is the source of truth. Return the filtered list even if it is empty.
          res.json({ success: true, count: validDbRecords.length, data: validDbRecords });
          return;
        }

        if (validDbRecords.length > 0) {
          res.json({ success: true, count: validDbRecords.length, data: validDbRecords });
          return;
        }
      }
    } catch (_) {}

    // Fallback only if the database is completely empty OR Drive API failed
    const combined = await UploadController.getCombinedUploadRecords();
    res.json({ success: true, count: combined.length, data: combined });
  }

  /**
   * DELETE /api/v1/uploads/:id
   * Deletes a record everywhere from Google Drive and PostgreSQL database.
   */
  static async deleteUpload(req: Request, res: Response): Promise<void> {
    const rawId = req.params.id;
    const id = String(rawId);

    if (!id) {
      res.status(400).json({ success: false, error: 'Record ID is required for deletion.' });
      return;
    }

    try {
      console.log(`🗑️ Processing full deletion for record ID: ${id}...`);

      // 1. Fetch record from Database
      let record: any = null;
      try {
        record = await prisma.driveUpload.findUnique({ where: { id } });
      } catch (_) {
        record = fallbackUploads.find((u) => u.id === id);
      }

      if (!record) {
        res.status(404).json({ success: false, error: 'Record not found in database.' });
        return;
      }

      // 2. Delete from Google Drive if driveFileId exists
      if (record.driveFileId) {
        await GoogleDriveService.deleteFile(record.driveFileId);
      }

      // 3. Delete everywhere from Database (Prisma PostgreSQL & fallback)
      try {
        await prisma.driveUpload.delete({ where: { id } });
        console.log(`✅ Deleted record ${id} from PostgreSQL database.`);
      } catch (_) {
        fallbackUploads = fallbackUploads.filter((u) => u.id !== id);
      }

      res.json({
        success: true,
        message: `Successfully deleted file from Google Drive and purged record from database!`,
        deletedId: id,
      });
    } catch (error: any) {
      console.error('❌ Deletion Controller Error:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Internal server error during deletion',
      });
    }
  }

  /**
   * GET /api/v1/download-pdf
   * Proxy endpoint to stream or download PDF files reliably.
   */
  static async downloadPdf(req: Request, res: Response): Promise<void> {
    const fileName = req.query.fileName as string | undefined;
    const driveFileId = req.query.driveFileId as string | undefined;
    const chapter = req.query.chapter as string | undefined;

    try {
      // Helper to check if file is valid binary PDF (starts with %PDF)
      const isValidPdfFile = async (filePath: string): Promise<boolean> => {
        try {
          const handle = await fs.open(filePath, 'r');
          const buffer = Buffer.alloc(4);
          await handle.read(buffer, 0, 4, 0);
          await handle.close();
          return buffer.toString() === '%PDF';
        } catch {
          return false;
        }
      };

      // 1. Check exact local static storage file
      if (fileName && fileName !== 'null' && fileName !== 'undefined') {
        const safeName = path.basename(fileName);
        const localPath = path.join(config.storagePath, safeName);
        if (await isValidPdfFile(localPath)) {
          console.log(`✅ Serving validated local PDF file: ${localPath}`);
          res.setHeader('Content-Type', 'application/pdf');
          res.sendFile(path.resolve(localPath));
          return;
        }
      }

      // 2. Check matching PDF by chapter/subject name in storage directory
      if (fileName || chapter) {
        const queryTerm = (fileName || chapter || '').toLowerCase().replace(/[^a-z0-9]/g, '');
        const filesInDir = await fs.readdir(config.storagePath).catch(() => []);

        for (const f of filesInDir) {
          if (f.endsWith('.pdf')) {
            const cleanF = f.toLowerCase().replace(/[^a-z0-9]/g, '');
            // Ensure exact or strong match so Maths is never served for Physics/Chemistry
            if (cleanF.includes(queryTerm) || queryTerm.includes(cleanF)) {
              const matchedPath = path.join(config.storagePath, f);
              if (await isValidPdfFile(matchedPath)) {
                console.log(`✅ Serving matched local PDF file: ${matchedPath}`);
                res.setHeader('Content-Type', 'application/pdf');
                res.sendFile(path.resolve(matchedPath));
                return;
              }
            }
          }
        }
      }

      // 3. Download directly from Google Drive API using Service Account if valid Drive File ID provided
      if (driveFileId && driveFileId !== 'null' && driveFileId !== 'undefined') {
        console.log(`🌐 Downloading PDF binary directly from Google Drive ID: ${driveFileId}...`);
        const pdfBuffer = await GoogleDriveService.downloadFile(driveFileId);

        if (pdfBuffer && pdfBuffer.slice(0, 4).toString() === '%PDF') {
          const targetName = fileName ? path.basename(fileName) : `Class_12_Mathematics_Chapter_5__Continuity_and_Differentiability.pdf`;
          const savePath = path.join(config.storagePath, targetName);
          await fs.writeFile(savePath, pdfBuffer).catch(() => {});

          res.setHeader('Content-Type', 'application/pdf');
          res.send(pdfBuffer);
          return;
        }
      }

      res.status(404).json({ success: false, error: 'PDF file not found for this chapter' });
    } catch (error: any) {
      console.error('❌ Download Proxy Error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  }
}
