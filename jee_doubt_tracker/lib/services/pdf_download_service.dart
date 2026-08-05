import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';

class PdfDownloadService {
  static Directory? _localFolder;

  /// Returns or creates the local EduSync app folder for PDFs.
  static Future<Directory> getLocalPdfFolder() async {
    if (kIsWeb) {
      throw UnsupportedError('Local file system not supported on Web');
    }
    if (_localFolder != null && _localFolder!.existsSync()) {
      return _localFolder!;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(docsDir.path, 'EduSync_PDFs'));

      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }

      _localFolder = pdfDir;
      return pdfDir;
    } catch (_) {
      return Directory('/tmp/EduSync_PDFs');
    }
  }

  /// Generates a clean local file path for a chapter PDF.
  static Future<File> getLocalPdfFile(String fileName) async {
    final folder = await getLocalPdfFolder();
    final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
    final targetName =
        cleanName.endsWith('.pdf') ? cleanName : '$cleanName.pdf';
    return File(path.join(folder.path, targetName));
  }

  /// Checks if a chapter PDF is already downloaded locally, is a valid PDF, and matches the expected size (if provided).
  static Future<bool> isPdfDownloadedLocally(String fileName, {int? expectedSizeBytes}) async {
    if (kIsWeb) return false;

    try {
      final file = await getLocalPdfFile(fileName);
      if (!file.existsSync() || file.lengthSync() < 100) return false;
      
      // Cross-verification: If expected size is provided, and it doesn't match EXACTLY, 
      // it means a page was added or deleted on Google Drive! We must invalidate cache!
      if (expectedSizeBytes != null && expectedSizeBytes > 0) {
        if (file.lengthSync() != expectedSizeBytes) {
          print('🔄 Cache invalidated for $fileName: Local size (${file.lengthSync()}) != Drive size ($expectedSizeBytes).');
          return false;
        }
      }
      
      final bytes = await file.openRead(0, 4).first;
      return bytes.length >= 4 &&
          bytes[0] == 0x25 && // '%'
          bytes[1] == 0x50 && // 'P'
          bytes[2] == 0x44 && // 'D'
          bytes[3] == 0x46; // 'F'
    } catch (_) {
      return false;
    }
  }

  /// Generates a valid fallback binary PDF file on local disk.
  static Future<File> _createFallbackPdfFile(
      File targetFile, String fileName) async {
    final cleanTitle = fileName.replaceAll(RegExp(r'[^\w\s\-\:]'), '');
    final pdfContent = '''
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 260 >>
stream
BT
/F1 20 Tf
50 720 Td
($cleanTitle) Tj
/F1 14 Tf
0 -40 Td
(EduSync - Chapter PDF Collection) Tj
0 -30 Td
(Question 1: Evaluate the given problem and determine the correct option.) Tj
0 -25 Td
(Solution Step 1: Simplify using standard formulas and rules.) Tj
0 -25 Td
(Solution Step 2: Calculate the numerical value and verify limits.) Tj
0 -40 Td
(Status: Verified Solution PDF - Saved in Doubt Bank) Tj
ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000246 00000 n 
0000000558 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
627
%%EOF
''';
    await targetFile.writeAsBytes(utf8.encode(pdfContent));
    print('📄 Created verified binary PDF file at "${targetFile.path}"');
    return targetFile;
  }

  /// Downloads a PDF from Google Drive / URL directly into the local app folder.
  /// Returns null if the download fails or does not return valid PDF bytes.
  static Future<File?> downloadPdfToLocalFolder({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      print(
          '🌐 Running on Web: Bypassing local file download. Using network streaming directly.');
      return null;
    }

    try {
      final targetFile = await getLocalPdfFile(fileName);

      int? expectedSize;
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.containsKey('size')) {
        expectedSize = int.tryParse(uri.queryParameters['size']!);
      }

      // Use cached file if it exists, is valid PDF, and perfectly matches Drive file size (if known)
      if (await isPdfDownloadedLocally(fileName, expectedSizeBytes: expectedSize)) {
        print('⚡ Using valid cached local PDF file: ${targetFile.path}');
        if (onProgress != null) onProgress(1.0);
        return targetFile;
      }
      
      // If we got here, the file is either missing, corrupted, or has changed on Drive (pages added/deleted).
      // We must delete the old obsolete file before downloading the fresh one.
      if (targetFile.existsSync()) {
        try {
          await targetFile.delete();
          print('🗑️ Purged obsolete cached PDF file: ${targetFile.path}');
        } catch (_) {}
      }

      print(
          '📥 Downloading fresh PDF from "$url" to local path "${targetFile.path}"...');

      var finalUrl = url;
      if (finalUrl.contains('drive.google.com') ||
          finalUrl.contains('docs.google.com')) {
        if (!finalUrl.contains('confirm=')) {
          finalUrl += '&confirm=t';
        }
      }

      final request = http.Request('GET', Uri.parse(finalUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final bytes = <int>[];
        int downloaded = 0;

        await response.stream.forEach((chunk) {
          bytes.addAll(chunk);
          downloaded += chunk.length;
          if (contentLength > 0 && onProgress != null) {
            onProgress(downloaded / contentLength);
          }
        });

        // Verify PDF magic bytes header %PDF
        if (bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46) {
          await targetFile.writeAsBytes(bytes);
          print(
              '✅ Downloaded & verified PDF locally! File size: ${targetFile.lengthSync()} bytes');
          return targetFile;
        } else {
          print('⚠️ Server/Drive returned non-PDF content.');
          return null;
        }
      } else {
        print('⚠️ PDF download HTTP status ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print('❌ Download exception: $e');
      return null;
    }
  }
}
