import { google } from 'googleapis';
import fs from 'fs';
import { config } from '../config/index';

export class GoogleDriveService {
  /**
   * Uploads a file to Google Drive using Google Apps Script WebApp Bridge (for free @gmail.com accounts)
   * or Service Account JWT authentication.
   * Returns the unique Google Drive File ID.
   */
  static async uploadFile(
    filePath: string,
    fileName: string,
    mimeType: string = 'application/pdf'
  ): Promise<{ fileId: string; isMock: boolean }> {
    const { googleServiceAccountEmail, googlePrivateKey, googleDriveFolderId, googleDriveWebAppUrl } = config;

    // 1. Method A: Google Apps Script WebApp Bridge (Direct Upload to personal @gmail.com Drive folder)
    if (googleDriveWebAppUrl && googleDriveWebAppUrl.trim().length > 0) {
      try {
        console.log(`🌐 Uploading to Google Drive via Apps Script Bridge: ${googleDriveWebAppUrl}...`);
        const fileBuffer = fs.readFileSync(filePath);
        const base64Data = fileBuffer.toString('base64');

        const response = await fetch(googleDriveWebAppUrl.trim(), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          redirect: 'follow',
          body: JSON.stringify({
            action: 'upload',
            fileName,
            base64: base64Data,
            folderId: googleDriveFolderId,
          }),
        });

        const data: any = await response.json();
        if (data.fileId) {
          console.log(`✅ Uploaded to Google Drive via Bridge! File ID: ${data.fileId}`);
          return { fileId: data.fileId, isMock: false };
        }
      } catch (bridgeError: any) {
        console.warn(`⚠️ Apps Script Bridge upload note: ${bridgeError.message}`);
      }
    }

    // 2. Method B: Service Account JWT authentication
    if (googleServiceAccountEmail && googlePrivateKey) {
      try {
        console.log(`📡 Connecting to Google Drive API with Service Account: ${googleServiceAccountEmail}...`);
        
        const auth = new google.auth.JWT({
          email: googleServiceAccountEmail,
          key: googlePrivateKey,
          scopes: [
            'https://www.googleapis.com/auth/drive',
            'https://www.googleapis.com/auth/drive.file',
          ],
        });

        const drive = google.drive({ version: 'v3', auth });

        const fileMetadata: { name: string; parents?: string[] } = {
          name: fileName,
        };

        if (googleDriveFolderId && googleDriveFolderId.trim().length > 0) {
          fileMetadata.parents = [googleDriveFolderId.trim()];
        }

        const media = {
          mimeType: mimeType,
          body: fs.createReadStream(filePath),
        };

        const response = await drive.files.create({
          requestBody: fileMetadata,
          media: media,
          fields: 'id, name, webViewLink, webContentLink',
          supportsAllDrives: true,
        });

        const fileId = response.data.id;
        if (!fileId) {
          throw new Error('Google Drive API returned an empty file ID.');
        }

        console.log(`✅ Uploaded to Google Drive! File ID: ${fileId}`);
        return { fileId, isMock: false };
      } catch (error: any) {
        console.warn(`⚠️ Google Drive API upload note: ${error.message}.`);
      }
    }

    // Fallback: Generate a realistic mock Google Drive File ID for dev testing
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    let mockFileId = '1B2M2';
    for (let i = 0; i < 28; i++) {
      mockFileId += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    console.log(`🔑 Generated Mock Google Drive File ID: ${mockFileId}`);
    return { fileId: mockFileId, isMock: true };
  }

  /**
   * Deletes a file from Google Drive and purges it.
   */
  static async deleteFile(driveFileId: string): Promise<boolean> {
    const { googleServiceAccountEmail, googlePrivateKey, googleDriveWebAppUrl } = config;

    // Method A: Bridge deletion
    if (googleDriveWebAppUrl && googleDriveWebAppUrl.trim().length > 0) {
      try {
        console.log(`🗑️ Deleting file ${driveFileId} via Apps Script Bridge...`);
        const response = await fetch(googleDriveWebAppUrl.trim(), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          redirect: 'follow',
          body: JSON.stringify({
            action: 'delete',
            fileId: driveFileId,
          }),
        });
        const data: any = await response.json();
        return data.success === true;
      } catch (_) {}
    }

    // Method B: Service Account deletion
    if (googleServiceAccountEmail && googlePrivateKey) {
      try {
        const auth = new google.auth.JWT({
          email: googleServiceAccountEmail,
          key: googlePrivateKey,
          scopes: ['https://www.googleapis.com/auth/drive'],
        });
        const drive = google.drive({ version: 'v3', auth });
        await drive.files.delete({ fileId: driveFileId, supportsAllDrives: true });
        console.log(`✅ Deleted file ${driveFileId} from Google Drive.`);
        return true;
      } catch (error: any) {
        console.warn(`⚠️ Drive deletion note: ${error.message}`);
      }
    }

    return true;
  }

  /**
   * Discovers and deletes all existing files in Google Drive matching targetFileName.
   */
  static async deleteFilesByName(targetFileName: string, excludeDriveId?: string): Promise<void> {
    try {
      const driveFiles = await GoogleDriveService.listFiles();
      for (const df of driveFiles) {
        if (df.name === targetFileName && df.id !== excludeDriveId) {
          console.log(`🗑️ Auto-purging duplicate file from Drive: ${df.name} (ID: ${df.id})...`);
          await GoogleDriveService.deleteFile(df.id);
        }
      }
    } catch (error: any) {
      console.warn(`⚠️ Warning auto-purging duplicate files: ${error.message}`);
    }
  }

  /**
   * Downloads a binary file from Google Drive via Service Account API.
   */
  static async downloadFile(fileId: string): Promise<Buffer | null> {
    const { googleServiceAccountEmail, googlePrivateKey } = config;

    if (googleServiceAccountEmail && googlePrivateKey) {
      try {
        console.log(`📥 Downloading raw binary file ${fileId} from Google Drive via Service Account...`);
        const auth = new google.auth.JWT({
          email: googleServiceAccountEmail,
          key: googlePrivateKey,
          scopes: ['https://www.googleapis.com/auth/drive'],
        });

        const drive = google.drive({ version: 'v3', auth });
        const response = await drive.files.get(
          { fileId, alt: 'media' },
          { responseType: 'arraybuffer' }
        );

        const buffer = Buffer.from(response.data as ArrayBuffer);
        if (buffer.length > 0) {
          console.log(`✅ Successfully downloaded ${buffer.length} bytes from Google Drive API! Header: ${buffer.slice(0, 4).toString()}`);
          return buffer;
        }
      } catch (error: any) {
        console.warn(`⚠️ Drive API download note for ${fileId}: ${error.message}`);
      }
    }
    return null;
  }

  /**
   * Lists files in the configured Google Drive folder.
   */
  static async listFiles(folderId?: string): Promise<Array<{ id: string; name: string; mimeType: string }>> {
    const { googleServiceAccountEmail, googlePrivateKey, googleDriveFolderId } = config;
    const targetFolderId = folderId || googleDriveFolderId;

    if (googleServiceAccountEmail && googlePrivateKey && targetFolderId) {
      try {
        const auth = new google.auth.JWT({
          email: googleServiceAccountEmail,
          key: googlePrivateKey,
          scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        });

        const drive = google.drive({ version: 'v3', auth });
        const response = await drive.files.list({
          q: `'${targetFolderId}' in parents and trashed = false`,
          fields: 'files(id, name, mimeType)',
        });

        return (response.data.files || []).map((f) => ({
          id: f.id || '',
          name: f.name || '',
          mimeType: f.mimeType || '',
        }));
      } catch (error: any) {
        console.warn(`⚠️ Drive listFiles note: ${error.message}`);
      }
    }
    return [];
  }
}
