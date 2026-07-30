import { Router } from 'express';
import multer from 'multer';
import { config } from '../config/index';
import { DoubtPdfController } from '../controllers/doubtPdfController';
import { UploadController } from '../controllers/uploadController';

const upload = multer({
  dest: `${config.storagePath}/temp_uploads/`,
  limits: { fileSize: config.maxFileSizeMB * 1024 * 1024 },
});

export const apiRouter = Router();

// Health check endpoint
apiRouter.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Doubt PDF Endpoints
apiRouter.get('/doubt-pdfs', DoubtPdfController.listDoubtPdfs);
apiRouter.post('/doubt-pdfs', DoubtPdfController.createDoubtPdf);
apiRouter.post('/doubt-pdfs/:id/append-page', upload.single('sourcePdf'), DoubtPdfController.appendPage);
apiRouter.delete('/doubt-pdfs/:id/pages/:pageIndex', DoubtPdfController.deletePage);

// Traffic Controller Google Drive & Database Upload Endpoints
apiRouter.post('/upload-to-drive', upload.single('pdfFile'), UploadController.uploadToDrive);
apiRouter.get('/uploads', UploadController.listUploads);
apiRouter.get('/download-pdf', UploadController.downloadPdf);
apiRouter.delete('/uploads/:id', UploadController.deleteUpload);
