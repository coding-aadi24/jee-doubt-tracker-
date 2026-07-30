import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs/promises';
import { config } from '../config/index';
import { PdfService } from '../services/pdfService';

// In-memory mock metadata storage (ready to be replaced with Prisma database)
interface DoubtPdfRecord {
  id: string;
  className: string;
  subject: string;
  chapter: string;
  title: string;
  fileName: string;
  pageCount: number;
  createdAt: string;
  updatedAt: string;
}

const doubtPdfs: DoubtPdfRecord[] = [];

export class DoubtPdfController {
  /**
   * GET /api/v1/doubt-pdfs
   * List doubt PDFs, optionally filtered by class, subject, chapter.
   */
  static async listDoubtPdfs(req: Request, res: Response): Promise<void> {
    const className = req.query.className as string | undefined;
    const subject = req.query.subject as string | undefined;
    const chapter = req.query.chapter as string | undefined;

    let filtered = [...doubtPdfs];
    if (className) filtered = filtered.filter(p => p.className === className);
    if (subject) filtered = filtered.filter(p => p.subject === subject);
    if (chapter) filtered = filtered.filter(p => p.chapter === chapter);

    res.json({ success: true, count: filtered.length, data: filtered });
  }

  /**
   * POST /api/v1/doubt-pdfs
   * Create a new doubt PDF metadata & file container.
   */
  static async createDoubtPdf(req: Request, res: Response): Promise<void> {
    const { className, subject, chapter, title } = req.body;

    if (!className || !subject || !chapter || !title) {
      res.status(400).json({ success: false, error: 'className, subject, chapter, and title are required.' });
      return;
    }

    const id = `pdf_${Date.now()}`;
    const safeTitle = String(title).replace(/[^a-zA-Z0-9_-]/g, '_');
    const fileName = `${className}_${subject}_${chapter}_${safeTitle}.pdf`;

    const record: DoubtPdfRecord = {
      id,
      className,
      subject,
      chapter,
      title,
      fileName,
      pageCount: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    doubtPdfs.push(record);

    res.status(201).json({
      success: true,
      message: 'Doubt PDF created successfully',
      data: record,
    });
  }

  /**
   * POST /api/v1/doubt-pdfs/:id/append-page
   * Append a page from uploaded source PDF to target doubt PDF.
   */
  static async appendPage(req: Request, res: Response): Promise<void> {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const pageNumber = parseInt(String(req.body.pageNumber || '1'), 10);
    const file = req.file;

    const record = doubtPdfs.find(p => p.id === id);
    if (!record) {
      res.status(404).json({ success: false, error: 'Doubt PDF record not found.' });
      return;
    }

    if (!file) {
      res.status(400).json({ success: false, error: 'Source PDF file is required.' });
      return;
    }

    const targetPath = path.join(config.storagePath, record.className, record.subject, record.fileName);

    try {
      await PdfService.extractAndAppendPage(file.path, pageNumber, targetPath);

      record.pageCount += 1;
      record.updatedAt = new Date().toISOString();

      // Clean up uploaded temporary source PDF
      await fs.unlink(file.path).catch(() => {});

      res.json({
        success: true,
        message: `Page ${pageNumber} appended to ${record.fileName}`,
        data: record,
      });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/doubt-pdfs/:id/pages/:pageIndex
   * Delete a page from a doubt PDF.
   */
  static async deletePage(req: Request, res: Response): Promise<void> {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const pageIndexParam = Array.isArray(req.params.pageIndex) ? req.params.pageIndex[0] : req.params.pageIndex;
    const index = parseInt(String(pageIndexParam), 10);

    const record = doubtPdfs.find(p => p.id === id);
    if (!record) {
      res.status(404).json({ success: false, error: 'Doubt PDF record not found.' });
      return;
    }

    const targetPath = path.join(config.storagePath, record.className, record.subject, record.fileName);

    try {
      await PdfService.deletePage(targetPath, index);
      record.pageCount = Math.max(0, record.pageCount - 1);
      record.updatedAt = new Date().toISOString();

      res.json({ success: true, message: `Page index ${index} deleted`, data: record });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

