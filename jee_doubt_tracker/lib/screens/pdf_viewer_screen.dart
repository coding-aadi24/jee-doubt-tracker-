import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_theme.dart';
import '../services/pdf_download_service.dart';
import '../config/api_config.dart';
import '../widgets/glass_neumorphic_widgets.dart';
import '../services/drawing_engine.dart';
import '../widgets/inking_canvas.dart';
import '../models/drawing_models.dart';
import 'upload_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  late final PdfViewerController _pdfViewerController;
  late final TextEditingController _pageInputController;
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

  final DrawingEngine _drawingEngine = DrawingEngine();
  Offset _currentScrollOffset = Offset.zero;
  bool _isDrawMode = false;
  // Unique key for reloading SfPdfViewer when native PDF is updated
  Key _pdfViewerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _pdfViewerController.addListener(_onPdfScroll);
    _pageInputController = TextEditingController(text: '1');
    _initPdfSource();
  }

  void _onPdfScroll() {
    if (_currentScrollOffset != _pdfViewerController.scrollOffset) {
      setState(() {
        _currentScrollOffset = _pdfViewerController.scrollOffset;
      });
    }
  }

  Future<void> _initPdfSource() async {
    final path = widget.filePath;
    if (path != null && path.isNotEmpty) {
      _hasPdfContent = true;

      if (path.startsWith('http://') || path.startsWith('https://')) {
        _isNetworkUrl = true;
        _startPdfDownloadFromUrl(path);
      } else if (!kIsWeb && File(path).existsSync()) {
        await _setupWorkingFile(File(path));
      }
    }
  }

  Future<void> _setupWorkingFile(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final workingFile = File('${tempDir.path}/working_${DateTime.now().millisecondsSinceEpoch}.pdf');
    if (workingFile.existsSync()) {
      workingFile.deleteSync();
    }
    await originalFile.copy(workingFile.path);

    if (mounted) {
      setState(() {
        _downloadedLocalPath = workingFile.path;
        _isLocalFile = true;
        _isDownloading = false;
        _hasErrorLoadingPdf = false;
        _pdfViewerKey = UniqueKey();
      });
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
        await _setupWorkingFile(downloadedFile);
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
    _pdfViewerController.removeListener(_onPdfScroll);
    _pdfViewerController.dispose();
    _pageInputController.dispose();
    _drawingEngine.dispose();
    super.dispose();
  }

  void _onPdfPageChanged(PdfPageChangedDetails details) {
    _onPageChanged(details.newPageNumber);
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
      _pageInputController.text = '$newPage';
      _drawingEngine.setPage(newPage);
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _pdfViewerController.jumpToPage(page);
    _onPageChanged(page);
  }

  Future<void> _insertBlankPage() async {
    if (_downloadedLocalPath == null) return;
    
    try {
      final bytes = File(_downloadedLocalPath!).readAsBytesSync();
      final document = PdfDocument(inputBytes: bytes);
      
      if (_currentPage < 1 || _currentPage > document.pages.count) return;

      // Get size of current page
      final currentPageObj = document.pages[_currentPage - 1]; // _currentPage is 1-indexed
      final pageSize = currentPageObj.size;
      
      // Remove default margins so the background color fills the entire page
      document.pageSettings.margins.all = 0;
      
      // Insert a new blank page at _currentPage index (which puts it right after the current page, since it's 0-indexed)
      final newPage = document.pages.insert(_currentPage, pageSize);
      
      // Draw a dark rectangle as fallback background
      newPage.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(28, 25, 23)), // AppTheme.backgroundDark equivalent
        bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );
      
      // Try drawing the branded logo image over the background
      try {
        final ByteData data = await rootBundle.load('assets/images/branded_page_bg.png');
        final Uint8List imageBytes = data.buffer.asUint8List();
        final PdfBitmap image = PdfBitmap(imageBytes);
        
        newPage.graphics.drawImage(
          image,
          Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
        );
      } catch (imageError) {
        debugPrint("Error drawing branded background image: $imageError");
      }
      
      // Save and overwrite the working file
      final savedBytes = await document.save();
      File(_downloadedLocalPath!).writeAsBytesSync(savedBytes);
      document.dispose();
      
      // Reload UI
      if (mounted) {
        setState(() {
          _totalPages++;
          _pdfViewerKey = UniqueKey(); // Force SfPdfViewer to rebuild and reload the file
          _goToPage(_currentPage + 1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inserted a dark blank page for notes!')),
        );
      }
    } catch (e) {
      debugPrint("Error inserting native blank page: $e");
    }
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
                                            _goToPage(_currentPage - 1);
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
                                          _goToPage(page);
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
                                            _goToPage(_currentPage + 1);
                                          }
                                        : null,
                                    tooltip: 'Next Page',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 50),
                            color: AppTheme.surfaceNeumorphic,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D24),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppTheme.neumorphicShadows(),
                              ),
                              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                            ),
                            onSelected: (value) {
                              if (value == 'zoom_in') {
                                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                              } else if (value == 'zoom_out') {
                                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                              } else if (value == 'draw') {
                                setState(() {
                                  _isDrawMode = !_isDrawMode;
                                });
                              } else if (value == 'flag') {
                                _showFlagPageModal(context);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'zoom_in',
                                child: Row(
                                  children: [
                                    Icon(Icons.zoom_in_rounded, color: AppTheme.primaryAccent, size: 22),
                                    const SizedBox(width: 12),
                                    Text('Zoom In', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'zoom_out',
                                child: Row(
                                  children: [
                                    Icon(Icons.zoom_out_rounded, color: AppTheme.primaryAccent, size: 22),
                                    const SizedBox(width: 12),
                                    Text('Zoom Out', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'draw',
                                child: Row(
                                  children: [
                                    Icon(Icons.draw_rounded, color: _isDrawMode ? AppTheme.primaryAccent : AppTheme.textSecondary, size: 22),
                                    const SizedBox(width: 12),
                                    Text(_isDrawMode ? 'Disable Drawing' : 'Enable Drawing', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'flag',
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_add_rounded, color: AppTheme.secondaryAccent, size: 22),
                                    const SizedBox(width: 12),
                                    Text('Flag Page for Doubt Bank', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Maximized PDF Viewport Surface
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
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
                                        ? Stack(
                                            children: [
                                          // Persistent PDF Viewer to retain zoom/scroll state
                                          _isLocalFile && _downloadedLocalPath != null
                                              ? SfPdfViewer.file(
                                                  File(_downloadedLocalPath!),
                                                  key: _pdfViewerKey,
                                                  controller: _pdfViewerController,
                                                  canShowScrollHead: false,
                                                  pageSpacing: 0,
                                                  enableDoubleTapZooming: !_isDrawMode,
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
                                                  onPageChanged: _onPdfPageChanged,
                                                )
                                              : _isNetworkUrl
                                                  ? SfPdfViewer.network(
                                                      widget.filePath!,
                                                      key: _pdfViewerKey,
                                                      controller: _pdfViewerController,
                                                      canShowScrollHead: false,
                                                      pageSpacing: 0,
                                                      enableDoubleTapZooming: !_isDrawMode,
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
                                                      onPageChanged: _onPdfPageChanged,
                                                    )
                                                  : _buildErrorScreen(),
                                            ],
                                          )
                                        : _buildErrorScreen(),
                          ),
                          
                          // The Dual-Layer Inking Canvas Overlay
                          Positioned.fill(
                            child: InkingCanvas(
                              engine: _drawingEngine,
                              isDrawMode: _isDrawMode,
                              scrollOffset: _currentScrollOffset,
                            ),
                          ),
                          
                          // Drawing Toolbar (Floating at Bottom)
                          if (_isDrawMode)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ListenableBuilder(
                                  listenable: _drawingEngine,
                                  builder: (context, _) {
                                    return GlassCard(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      borderRadius: 30,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildToolButton(
                                            icon: Icons.edit_rounded,
                                            isActive: _drawingEngine.mode == DrawingMode.pen,
                                            overrideActiveColor: _drawingEngine.activeColor,
                                            onTap: () {
                                              if (_drawingEngine.mode == DrawingMode.pen) {
                                                _showPenConfigModal(context);
                                              } else {
                                                _drawingEngine.setMode(DrawingMode.pen);
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _buildToolButton(
                                            icon: Icons.cleaning_services_rounded,
                                            isActive: _drawingEngine.mode == DrawingMode.eraser,
                                            onTap: () => _drawingEngine.setMode(DrawingMode.eraser),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildToolButton(
                                            icon: Icons.gesture_rounded, // Lasso
                                            isActive: _drawingEngine.mode == DrawingMode.lasso,
                                            onTap: () => _drawingEngine.setMode(DrawingMode.lasso),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildToolButton(
                                            icon: Icons.pan_tool_rounded, // Pan Tool
                                            isActive: _drawingEngine.mode == DrawingMode.pan,
                                            onTap: () => _drawingEngine.setMode(DrawingMode.pan),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 12),
                                            height: 24,
                                            width: 1,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          NeumorphicIconButton(
                                            icon: Icons.note_add_rounded,
                                            size: 40,
                                            iconColor: AppTheme.secondaryAccent,
                                            onPressed: _insertBlankPage,
                                            tooltip: 'Insert Dark Blank Page',
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildToolButton({required IconData icon, required bool isActive, required VoidCallback onTap, Color? overrideActiveColor}) {
    final activeColor = overrideActiveColor ?? AppTheme.primaryAccent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isActive ? activeColor : Colors.transparent),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showPenConfigModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassNeumorphicCard(
              borderRadius: 28,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pen Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('Color', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildColorSwatch(const Color(0xFFFACC15), setModalState), // Yellow
                      _buildColorSwatch(const Color(0xFFEF4444), setModalState), // Red
                      _buildColorSwatch(const Color(0xFF3B82F6), setModalState), // Blue
                      _buildColorSwatch(const Color(0xFF10B981), setModalState), // Green
                      _buildColorSwatch(Colors.white, setModalState),            // White
                      _buildColorSwatch(const Color(0xFF94A3B8), setModalState), // Gray
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Thickness', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Slider(
                    value: _drawingEngine.activeThickness,
                    min: 1.0,
                    max: 12.0,
                    activeColor: _drawingEngine.activeColor,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (value) {
                      setModalState(() {
                        _drawingEngine.setPenConfig(_drawingEngine.activeColor, value);
                      });
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildColorSwatch(Color color, StateSetter setModalState) {
    final isSelected = _drawingEngine.activeColor == color;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _drawingEngine.setPenConfig(color, _drawingEngine.activeThickness);
        });
        setState(() {});
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
          ],
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
