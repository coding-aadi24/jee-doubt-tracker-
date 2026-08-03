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
import '../widgets/glass_neumorphic_widgets.dart';
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

  bool _isModalOpen = false;

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
        _isNetworkUrl = true;
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
          _isNetworkUrl = true;
          _hasErrorLoadingPdf = false;
        });
      }
    }
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
      body: AmbientBackground(
        child: AnimatedScale(
          scale: _isModalOpen ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: _isModalOpen ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: SafeArea(
              child: Column(
                children: [
                  // Top Frosted Glass Controls Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      borderRadius: 22,
                      child: Row(
                        children: [
                          NeumorphicIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            size: 38,
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  NeumorphicIconButton(
                                    icon: Icons.chevron_left_rounded,
                                    size: 34,
                                    onPressed: _currentPage > 1
                                        ? () {
                                            _pdfViewerController.previousPage();
                                          }
                                        : null,
                                    tooltip: 'Previous Page',
                                  ),
                                  const SizedBox(width: 6),

                                  // Inset Neumorphic Page Box
                                  Container(
                                    width: 44,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14161E),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                      boxShadow: AppTheme.neumorphicPressedShadows(),
                                    ),
                                    child: TextField(
                                      controller: _pageInputController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        counterText: '',
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
                                        final page = int.tryParse(value);
                                        if (page != null && page >= 1 && page <= _totalPages) {
                                          _pdfViewerController.jumpToPage(page);
                                        } else {
                                          _pageInputController.text = '$_currentPage';
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('⚠️ Page number must be between 1 and $_totalPages'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '/ $_totalPages',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  NeumorphicIconButton(
                                    icon: Icons.chevron_right_rounded,
                                    size: 34,
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
                          const SizedBox(width: 4),
                          NeumorphicIconButton(
                            icon: Icons.zoom_in_rounded,
                            iconColor: AppTheme.primaryAccent,
                            size: 36,
                            onPressed: () {
                              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                            },
                            tooltip: 'Zoom In',
                          ),
                          const SizedBox(width: 6),
                          NeumorphicIconButton(
                            icon: Icons.zoom_out_rounded,
                            iconColor: AppTheme.primaryAccent,
                            size: 36,
                            onPressed: () {
                              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                            },
                            tooltip: 'Zoom Out',
                          ),
                          const SizedBox(width: 6),
                          NeumorphicIconButton(
                            icon: Icons.bookmark_add_rounded,
                            iconColor: AppTheme.secondaryAccent,
                            size: 36,
                            onPressed: () => _showFlagPageModal(context),
                            tooltip: 'Flag Page for Doubt Bank',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Maximized PDF Viewport Surface
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        boxShadow: AppTheme.glassShadow,
                      ),
                      child: _isDownloading
                          ? Container(
                              color: AppTheme.backgroundDark,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: AppTheme.primaryAccent),
                                    SizedBox(height: 18),
                                    Text(
                                      'Downloading PDF from Drive... ${(_downloadProgress * 100).toInt()}%',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
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
        ),
      ),
    );
  }

  void _showFlagPageModal(BuildContext context) {
    setState(() => _isModalOpen = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassNeumorphicCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(22),
          borderColor: AppTheme.primaryAccent.withOpacity(0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GlassCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(8),
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    shadows: const [],
                    child: Icon(Icons.bookmark_rounded, color: AppTheme.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Flag Page $_currentPage for Doubt Bank',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Select destination doubt collection option:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              NeumorphicCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(12),
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
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryAccent, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create New Doubt PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Save page to Class → Subject → Chapter', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NeumorphicCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(12),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToExistingPdfModal(context);
                },
                child: Row(
                  children: [
                    Icon(Icons.snippet_folder_rounded, color: AppTheme.secondaryAccent, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add to Existing Doubt PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Append page to shared chapter file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isModalOpen = false);
    });
  }

  void _showAddToExistingPdfModal(BuildContext parentContext) {
    setState(() => _isModalOpen = true);

    String selectedClass = 'Class 12';
    String selectedSubject = 'Mathematics';
    String? selectedChapter = 'Chapter 5: Continuity and Differentiability';
    int targetPageNumber = _currentPage;
    bool isUploading = false;
    List<String> existingChapters = [];
    bool isLoadingChapters = true;
    bool isFetchingChapters = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                      isFetchingChapters = false;
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
                isFetchingChapters = false;
              });
            }

            if (isLoadingChapters && !isFetchingChapters) {
              isFetchingChapters = true;
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

                if (!mounted) return;
                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.accentEmerald,
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
                  }
                } else {
                  if (mounted) {
                    setModalState(() {
                      isUploading = false;
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('❌ Upload error: ${response.body}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  setModalState(() {
                    isUploading = false;
                  });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('❌ Connection error: $e')),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: GlassNeumorphicCard(
                borderRadius: 28,
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.snippet_folder_rounded, color: AppTheme.secondaryAccent, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add to Existing Doubt PDF',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          NeumorphicIconButton(
                            icon: Icons.close_rounded,
                            size: 32,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Select Class
                      Text('Select Class:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Class 11', 'Class 12'].map((cls) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: NeumorphicChip(
                              label: cls,
                              isSelected: selectedClass == cls,
                              onTap: () {
                                setModalState(() {
                                  selectedClass = cls;
                                  isLoadingChapters = true;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 2. Select Subject
                      Text('Select Subject:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Physics', 'Chemistry', 'Mathematics'].map((subj) {
                          return NeumorphicChip(
                            label: subj,
                            isSelected: selectedSubject == subj,
                            onTap: () {
                              setModalState(() {
                                selectedSubject = subj;
                                isLoadingChapters = true;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // 3. Select Chapter PDF
                      Text('Select Chapter Doubt PDF:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      isLoadingChapters
                          ? Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppTheme.secondaryAccent)))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                boxShadow: AppTheme.neumorphicPressedShadows(),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: AppTheme.surfaceNeumorphic,
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
                                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
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
                          Text('Page to Extract & Append:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GlassCard(
                            borderRadius: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                            borderColor: AppTheme.primaryAccent,
                            shadows: const [],
                            child: Text(
                              'Page $targetPageNumber',
                              style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 5. Submit Button
                      NeumorphicButton(
                        onPressed: isUploading ? null : submitAppendPage,
                        isGlowing: true,
                        accentColor: AppTheme.secondaryAccent,
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploading)
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            else
                              const Icon(Icons.cloud_upload_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isUploading ? 'Updating Drive...' : 'Append Page & Update Drive',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isModalOpen = false);
    });
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
              Icon(Icons.error_outline_rounded, color: AppTheme.secondaryAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to Load PDF',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load file for "${widget.fileName}". Please ensure the PDF is uploaded to Google Drive.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              NeumorphicButton(
                onPressed: () {
                  setState(() {
                    _hasErrorLoadingPdf = false;
                    _isDownloading = false;
                    _downloadedLocalPath = null;
                    _isLocalFile = false;
                    _isNetworkUrl = false;
                  });
                  _initPdfSource();
                },
                isGlowing: true,
                accentColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Retry Loading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
