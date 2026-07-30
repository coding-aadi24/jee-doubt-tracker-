class ChapterPdfStore {
  // Key format: "className|subject|chapter" -> local File Path
  static final Map<String, String> _chapterPdfPaths = {};

  static void registerChapterPdf({
    required String className,
    required String subject,
    required String chapter,
    required String filePath,
  }) {
    final key = _makeKey(className, subject, chapter);
    _chapterPdfPaths[key] = filePath;
  }

  static String? getChapterPdfPath({
    required String className,
    required String subject,
    required String chapter,
  }) {
    final key = _makeKey(className, subject, chapter);
    return _chapterPdfPaths[key];
  }

  static bool hasPdf({
    required String className,
    required String subject,
    required String chapter,
  }) {
    final key = _makeKey(className, subject, chapter);
    return _chapterPdfPaths.containsKey(key);
  }

  static String _makeKey(String className, String subject, String chapter) {
    return '${className.trim()}|${subject.trim()}|${chapter.trim()}';
  }
}
