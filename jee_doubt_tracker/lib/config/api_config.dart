class ApiConfig {
  /// Base API URL for backend calls.
  /// 
  /// Options for testing & production:
  /// - Local PC Wi-Fi IP (e.g. 'http://192.168.1.15:5000')
  /// - Ngrok / Tunnel (e.g. 'https://xxxx.ngrok-free.app')
  /// - Production Cloud Server (e.g. 'https://jee-doubt-backend.onrender.com')
  static String baseUrl = 'https://jee-doubt-tracker.onrender.com';
  
  /// Helper getter for uploads endpoint
  static String get uploadsUrl => '$baseUrl/api/v1/uploads';

  /// Helper getter for upload to drive endpoint
  static String get uploadToDriveUrl => '$baseUrl/api/v1/upload-to-drive';

  /// Helper getter for PDF download endpoint
  static String downloadPdfUrl({String? fileName, String? driveFileId, String? chapter}) {
    if (chapter != null) {
      return '$baseUrl/api/v1/download-pdf?chapter=${Uri.encodeComponent(chapter)}';
    }
    return '$baseUrl/api/v1/download-pdf?fileName=${Uri.encodeComponent(fileName ?? '')}&driveFileId=${Uri.encodeComponent(driveFileId ?? '')}';
  }
}
