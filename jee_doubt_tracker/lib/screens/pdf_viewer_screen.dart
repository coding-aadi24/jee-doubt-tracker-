import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_theme.dart';
import '../services/pdf_download_service.dart';
import '../config/api_config.dart';
import 'upload_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileName;
  final String? filePath;

  const PdfViewerScreen({
    Key? key,
    required this.fileName,
    this.filePath,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _pageInputController = TextEditingController(text: '1');
  int _currentPage = 1;
  int _totalPages = 1;

  bool _isLocalFile = false;
  bool _isNetworkUrl = false;
  bool _hasPdfContent = false;
  bool _isDownloading = false;
  bool _hasErrorLoadingPdf = false;
  double _downloadProgress = 0.0;
  String? _downloadedLocalPath;

  @override
  void initState() {
    super.initState();
    _initPdfSource();
  }

  Future<void> _initPdfSource() async {
    final path = widget.filePath;
    if (path != null && path.isNotEmpty) {
      _hasPdfContent = true;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        _startPdfDownloadFromUrl(path);
      } else if (File(path).existsSync()) {
        if (mounted) {
          setState(() {
            _downloadedLocalPath = path;
            _isLocalFile = true;
          });
        }
      }
    }
  }

  Future<void> _startPdfDownloadFromUrl(String url) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
      _hasErrorLoadingPdf = false;
    });

    final downloadedFile = await PdfDownloadService.downloadPdfToLocalFolder(
      url: url,
      fileName: widget.fileName,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

    if (mounted) {
      if (downloadedFile != null && downloadedFile.existsSync() && downloadedFile.lengthSync() > 1000) {
        setState(() {
          _downloadedLocalPath = downloadedFile.path;
          _isLocalFile = true;
          _isDownloading = false;
          _hasErrorLoadingPdf = false;
        });
      } else {
        setState(() {
          _isDownloading = false;
          _hasErrorLoadingPdf = true;
        });
      }
    }
  }

  Uint8List _generateSamplePdfBytes(String title) {
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s\-\:]'), '');
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
(JEE Doubt Tracker - Chapter PDF Collection) Tj
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
    return Uint8List.fromList(utf8.encode(pdfContent));
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
      _pageInputController.text = '$newPage';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Glass Header with Custom Page Box Indicator [ 1 ] of 54
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildGlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary, size: 20),
                                onPressed: _currentPage > 1
                                    ? () {
                                        _pdfViewerController.previousPage();
                                      }
                                    : null,
                                tooltip: 'Previous Page',
                              ),
                              const SizedBox(width: 2),

                              // Styled Page Number Input Box [ 1 ]
                              Container(
                                width: 38,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                ),
                                child: TextField(
                                  controller: _pageInputController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (value) {
                                    final page = int.tryParse(value);
                                    if (page != null && page >= 1 && page <= _totalPages) {
                                      _pdfViewerController.jumpToPage(page);
                                    } else {
                                      _pageInputController.text = '$_currentPage';
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ $_totalPages',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),

                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary, size: 20),
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                        _pdfViewerController.nextPage();
                                      }
                                    : null,
                                tooltip: 'Next Page',
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: const Icon(Icons.zoom_in, color: AppTheme.primaryAccent, size: 20),
                        onPressed: () {
                          _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                        },
                        tooltip: 'Zoom In',
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: const Icon(Icons.zoom_out, color: AppTheme.primaryAccent, size: 20),
                        onPressed: () {
                          _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                        },
                        tooltip: 'Zoom Out',
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: const Icon(Icons.bookmark_add_rounded, color: AppTheme.primaryAccent, size: 20),
                        onPressed: () => _showFlagPageModal(context),
                        tooltip: 'Flag Page',
                      ),
                    ],
                  ),
                ),
              ),

              // Maximized PDF Canvas Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                    boxShadow: AppTheme.glassShadow,
                  ),
                  child: _isDownloading
                      ? Container(
                          color: AppTheme.backgroundDark,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: AppTheme.primaryAccent),
                                const SizedBox(height: 18),
                                Text(
                                  'Downloading PDF from Drive... ${(_downloadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Saving directly to your local device app folder',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _hasErrorLoadingPdf
                          ? _buildErrorScreen()
                          : _hasPdfContent
                              ? (_isLocalFile && _downloadedLocalPath != null
                                  ? SfPdfViewer.file(
                                      File(_downloadedLocalPath!),
                                      key: Key(_downloadedLocalPath!),
                                      controller: _pdfViewerController,
                                      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                        setState(() {
                                          _totalPages = details.document.pages.count;
                                        });
                                      },
                                      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                        setState(() {
                                          _hasErrorLoadingPdf = true;
                                        });
                                      },
                                      onPageChanged: (PdfPageChangedDetails details) {
                                        _onPageChanged(details.newPageNumber);
                                      },
                                    )
                                  : _isNetworkUrl
                                      ? SfPdfViewer.network(
                                          widget.filePath!,
                                          key: Key(widget.filePath!),
                                          controller: _pdfViewerController,
                                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                                            setState(() {
                                              _totalPages = details.document.pages.count;
                                            });
                                          },
                                          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                                            setState(() {
                                              _hasErrorLoadingPdf = true;
                                            });
                                          },
                                          onPageChanged: (PdfPageChangedDetails details) {
                                            _onPageChanged(details.newPageNumber);
                                          },
                                        )
                                      : _buildErrorScreen())
                              : _buildErrorScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.surfaceGlassCard,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppTheme.glassBorder, width: 1.2),
            boxShadow: AppTheme.glassShadow,
          ),
          child: child,
        ),
      ),
    );
  }

  void _showFlagPageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: AppTheme.primaryAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Flag Page $_currentPage for Doubt Bank',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select destination doubt collection:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryAccent),
              title: const Text('Create New Doubt PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Extract Page $_currentPage & save to Class → Subject → Chapter', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadScreen(
                      initialFilePath: widget.filePath,
                      initialFileName: widget.fileName,
                      selectedPageNumber: _currentPage,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.snippet_folder_rounded, color: AppTheme.secondaryAccent),
              title: const Text('Add to Existing Doubt PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: const Text('Append to shared chapter file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showAddToExistingPdfModal(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToExistingPdfModal(BuildContext parentContext) {
    String selectedClass = 'Class 12';
    String selectedSubject = 'Mathematics';
    String? selectedChapter = 'Chapter 5: Continuity and Differentiability';
    int targetPageNumber = _currentPage;
    bool isUploading = false;
    List<String> existingChapters = [];
    bool isLoadingChapters = true;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void fetchChapters() async {
              try {
                final response = await http
                    .get(Uri.parse(ApiConfig.uploadsUrl))
                    .timeout(const Duration(seconds: 3));

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['success'] == true && data['data'] is List) {
                    final List records = data['data'];
                    final List<String> found = [];
                    for (var r in records) {
                      if (r['className'] == selectedClass && r['subject'] == selectedSubject) {
                        final ch = r['chapter']?.toString();
                        if (ch != null && !found.contains(ch)) {
                          found.add(ch);
                        }
                      }
                    }
                    setModalState(() {
                      existingChapters = found;
                      if (found.isNotEmpty) {
                        selectedChapter = found.first;
                      } else {
                        if (selectedSubject == 'Mathematics') {
                          selectedChapter = 'Chapter 5: Continuity and Differentiability';
                        } else if (selectedSubject == 'Physics') {
                          selectedChapter = 'Chapter 1: Electric Charges and Fields';
                        } else {
                          selectedChapter = 'Chapter 7: Alcohols, Phenols and Ethers';
                        }
                      }
                      isLoadingChapters = false;
                    });
                    return;
                  }
                }
              } catch (_) {}

              setModalState(() {
                if (selectedSubject == 'Mathematics') {
                  selectedChapter = 'Chapter 5: Continuity and Differentiability';
                } else if (selectedSubject == 'Physics') {
                  selectedChapter = 'Chapter 1: Electric Charges and Fields';
                } else {
                  selectedChapter = 'Chapter 7: Alcohols, Phenols and Ethers';
                }
                isLoadingChapters = false;
              });
            }

            if (isLoadingChapters) {
              fetchChapters();
            }

            Future<void> submitAppendPage() async {
              final activeSourcePath = _downloadedLocalPath ?? widget.filePath;
              if (activeSourcePath == null || activeSourcePath.isEmpty || !File(activeSourcePath).existsSync()) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('⚠️ Source PDF file not found locally.')),
                );
                return;
              }

              if (selectedChapter == null || selectedChapter!.isEmpty) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('⚠️ Please select a target chapter.')),
                );
                return;
              }

              setModalState(() {
                isUploading = true;
              });

              try {
                final uri = Uri.parse(ApiConfig.uploadToDriveUrl);
                final request = http.MultipartRequest('POST', uri);

                request.files.add(await http.MultipartFile.fromPath('pdfFile', activeSourcePath));
                request.fields['className'] = selectedClass;
                request.fields['subject'] = selectedSubject;
                request.fields['chapter'] = selectedChapter!;
                request.fields['pageNumber'] = '$targetPageNumber';
                request.fields['forceAppend'] = 'true';
                request.fields['userName'] = 'JEE Aspirant';

                final streamedResponse = await request.send();
                final response = await http.Response.fromStream(streamedResponse);

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF30D158),
                      duration: const Duration(seconds: 4),
                      content: Row(
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '✅ Page $targetPageNumber appended to "$selectedChapter" & updated on Google Drive!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  setModalState(() {
                    isUploading = false;
                  });
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('❌ Upload error: ${response.body}')),
                  );
                }
              } catch (e) {
                setModalState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('❌ Connection error: $e')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.snippet_folder_rounded, color: AppTheme.secondaryAccent, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add to Existing Doubt PDF',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Select Class
                    const Text('Select Class:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Class 11', 'Class 12'].map((cls) {
                        final isSel = selectedClass == cls;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(cls),
                            selected: isSel,
                            selectedColor: AppTheme.primaryAccent,
                            backgroundColor: AppTheme.surfaceGlassCard,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedClass = cls;
                                  isLoadingChapters = true;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 2. Select Subject
                    const Text('Select Subject:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Physics', 'Chemistry', 'Mathematics'].map((subj) {
                        final isSel = selectedSubject == subj;
                        return ChoiceChip(
                          label: Text(subj),
                          selected: isSel,
                          selectedColor: AppTheme.secondaryAccent,
                          backgroundColor: AppTheme.surfaceGlassCard,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : AppTheme.textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedSubject = subj;
                                isLoadingChapters = true;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Select Chapter PDF
                    const Text('Select Chapter Doubt PDF:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    isLoadingChapters
                        ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppTheme.secondaryAccent)))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGlassCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: AppTheme.surfaceDark,
                                value: selectedChapter,
                                items: (existingChapters.isNotEmpty
                                        ? existingChapters
                                        : [
                                            selectedChapter ?? 'Chapter 5: Continuity and Differentiability'
                                          ])
                                    .map((ch) => DropdownMenuItem(
                                          value: ch,
                                          child: Text(
                                            ch,
                                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedChapter = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),

                    // 4. Page Number Selection
                    Row(
                      children: [
                        const Text('Page to Extract & Append:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryAccent),
                          ),
                          child: Text(
                            'Page $targetPageNumber',
                            style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : submitAppendPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryAccent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded, color: Colors.black),
                        label: Text(
                          isUploading ? 'Updating Google Drive...' : 'Append Page & Update Drive',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: AppTheme.backgroundDark,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.secondaryAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load PDF',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load file for "${widget.fileName}". Please ensure the PDF is uploaded to Google Drive.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasErrorLoadingPdf = false;
                    _isDownloading = false;
                  });
                  _initPdfSource();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Loading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
