import fs from 'fs/promises';
import path from 'path';
import { PDFDocument } from 'pdf-lib';
import { config } from '../config/index';

export class PdfService {
  /**
   * Extract specific page from source PDF and append it to target doubt PDF.
   */
  static async extractAndAppendPage(
    sourcePdfPath: string,
    sourcePageNumber: number, // 1-indexed page number
    targetDoubtPdfPath: string
  ): Promise<void> {
    // Read source PDF
    const sourceBuffer = await fs.readFile(sourcePdfPath);
    const sourcePdfDoc = await PDFDocument.load(sourceBuffer, { ignoreEncryption: true });

    const totalPages = sourcePdfDoc.getPageCount();
    if (sourcePageNumber < 1 || sourcePageNumber > totalPages) {
      throw new Error(`Invalid page number ${sourcePageNumber}. Source PDF has ${totalPages} pages.`);
    }

    // Load or initialize target PDF
    let targetPdfDoc: PDFDocument;
    try {
      const targetBuffer = await fs.readFile(targetDoubtPdfPath);
      targetPdfDoc = await PDFDocument.load(targetBuffer, { ignoreEncryption: true });
    } catch {
      // Create new PDF if target file doesn't exist yet
      targetPdfDoc = await PDFDocument.create();
    }

    // Copy source page into target document
    const [copiedPage] = await targetPdfDoc.copyPages(sourcePdfDoc, [sourcePageNumber - 1]);
    targetPdfDoc.addPage(copiedPage);

    // Ensure directory exists and write updated PDF
    await fs.mkdir(path.dirname(targetDoubtPdfPath), { recursive: true });
    const pdfBytes = await targetPdfDoc.save();
    await fs.writeFile(targetDoubtPdfPath, pdfBytes);
  }

  /**
   * Remove a page by index from a doubt PDF file.
   */
  static async deletePage(pdfPath: string, pageIndex: number): Promise<void> {
    const pdfBuffer = await fs.readFile(pdfPath);
    const pdfDoc = await PDFDocument.load(pdfBuffer);

    if (pageIndex < 0 || pageIndex >= pdfDoc.getPageCount()) {
      throw new Error(`Invalid page index ${pageIndex}. PDF has ${pdfDoc.getPageCount()} pages.`);
    }

    pdfDoc.removePage(pageIndex);

    const pdfBytes = await pdfDoc.save();
    await fs.writeFile(pdfPath, pdfBytes);
  }
}
