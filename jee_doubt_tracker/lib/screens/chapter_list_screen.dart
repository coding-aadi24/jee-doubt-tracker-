import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/chapter_pdf_store.dart';
import '../config/api_config.dart';
import 'pdf_viewer_screen.dart';
import 'upload_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final String subjectTitle; // e.g. "Class 12 — Physics"
  final String className;    // e.g. "Class 12"
  final String subjectName;  // e.g. "Physics"
  final Color accentColor;
  final IconData icon;

  const ChapterListScreen({
    Key? key,
    required this.subjectTitle,
    required this.className,
    required this.subjectName,
    required this.accentColor,
    required this.icon,
  }) : super(key: key);

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Set<String> _availableChaptersInDb = {};
  Map<String, String> _chapterFilePaths = {};
  bool _isLoadingDb = true;

  static const Map<String, Map<String, List<String>>> _chaptersDatabase = {
    'Class 11': {
      'Physics': [
        'Chapter 1: Units and Measurements',
        'Chapter 2: Motion in a Straight Line',
        'Chapter 3: Motion in a Plane',
        'Chapter 4: Laws of Motion',
        'Chapter 5: Work, Energy and Power',
        'Chapter 6: System of Particles and Rotational Motion',
        'Chapter 7: Gravitation',
        'Chapter 8: Mechanical Properties of Solids',
        'Chapter 9: Mechanical Properties of Fluids',
        'Chapter 10: Thermal Properties of Matter',
        'Chapter 11: Thermodynamics',
        'Chapter 12: Kinetic Theory',
        'Chapter 13: Oscillations',
        'Chapter 14: Waves',
      ],
      'Chemistry': [
        'Chapter 1: Some Basic Concepts of Chemistry',
        'Chapter 2: Structure of Atom',
        'Chapter 3: Classification of Elements and Periodicity in Properties',
        'Chapter 4: Chemical Bonding and Molecular Structure',
        'Chapter 5: Thermodynamics',
        'Chapter 6: Equilibrium',
        'Chapter 7: Redox Reactions',
        'Chapter 8: Organic Chemistry: Some Basic Principles and Techniques',
        'Chapter 9: Hydrocarbons',
      ],
      'Mathematics': [
        'Chapter 1: Sets',
        'Chapter 2: Relations and Functions',
        'Chapter 3: Trigonometric Functions',
        'Chapter 4: Complex Numbers and Quadratic Equations',
        'Chapter 5: Linear Inequalities',
        'Chapter 6: Permutations and Combinations',
        'Chapter 7: Binomial Theorem',
        'Chapter 8: Sequences and Series',
        'Chapter 9: Straight Lines',
        'Chapter 10: Conic Sections',
        'Chapter 11: Introduction to Three-Dimensional Geometry',
        'Chapter 12: Limits and Derivatives',
        'Chapter 13: Statistics',
        'Chapter 14: Probability',
      ],
    },
    'Class 12': {
      'Physics': [
        'Chapter 1: Electric Charges and Fields',
        'Chapter 2: Electrostatic Potential and Capacitance',
        'Chapter 3: Current Electricity',
        'Chapter 4: Moving Charges and Magnetism',
        'Chapter 5: Magnetism and Matter',
        'Chapter 6: Electromagnetic Induction',
        'Chapter 7: Alternating Current',
        'Chapter 8: Electromagnetic Waves',
        'Chapter 9: Ray Optics and Optical Instruments',
        'Chapter 10: Wave Optics',
        'Chapter 11: Dual Nature of Radiation and Matter',
        'Chapter 12: Atoms',
        'Chapter 13: Nuclei',
        'Chapter 14: Semiconductor Electronics: Materials, Devices and Simple Circuits',
      ],
      'Chemistry': [
        'Chapter 1: Solutions',
        'Chapter 2: Electrochemistry',
        'Chapter 3: Chemical Kinetics',
        'Chapter 4: The d- and f-Block Elements',
        'Chapter 5: Coordination Compounds',
        'Chapter 6: Haloalkanes and Haloarenes',
        'Chapter 7: Alcohols, Phenols and Ethers',
        'Chapter 8: Aldehydes, Ketones and Carboxylic Acids',
        'Chapter 9: Amines',
        'Chapter 10: Biomolecules',
      ],
      'Mathematics': [
        'Chapter 1: Relations and Functions',
        'Chapter 2: Inverse Trigonometric Functions',
        'Chapter 3: Matrices',
        'Chapter 4: Determinants',
        'Chapter 5: Continuity and Differentiability',
        'Chapter 6: Application of Derivatives',
        'Chapter 7: Integrals',
        'Chapter 8: Application of Integrals',
        'Chapter 9: Differential Equations',
        'Chapter 10: Vector Algebra',
        'Chapter 11: Three Dimensional Geometry',
        'Chapter 12: Linear Programming',
        'Chapter 13: Probability',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchUploadedChaptersFromDatabase();
  }

  Future<void> _fetchUploadedChaptersFromDatabase() async {
    final Set<String> available = {};
    final Map<String, String> paths = {};

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.uploadsUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final List records = data['data'];
          for (var record in records) {
            final cls = record['className'];
            final subj = record['subject'];
            final ch = record['chapter'];
            final fileName = record['fileName'];
            final driveId = record['driveFileId'];

            if (cls == widget.className && subj == widget.subjectName && ch != null) {
              final chapterStr = ch.toString();
              available.add(chapterStr);
              final fName = fileName?.toString() ?? '';
              final dId = driveId?.toString() ?? '';
              paths[chapterStr] = ApiConfig.downloadPdfUrl(fileName: fName, driveFileId: dId);
            }
          }
        }
      }
    } catch (_) {
      // Backend unreachable or offline
    }

    if (mounted) {
      setState(() {
        _availableChaptersInDb = available;
        _chapterFilePaths = paths;
        _isLoadingDb = false;
      });
    }
  }

  bool _isPdfAvailable(String chapterTitle) {
    final normTitle = chapterTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final ch in _availableChaptersInDb) {
      final normCh = ch.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normCh == normTitle || normCh.contains(normTitle) || normTitle.contains(normCh)) {
        return true;
      }
    }
    return ChapterPdfStore.hasPdf(
      className: widget.className,
      subject: widget.subjectName,
      chapter: chapterTitle,
    );
  }

  List<String> get _allChapters {
    return _chaptersDatabase[widget.className]?[widget.subjectName] ?? [];
  }

  List<String> get _filteredChapters {
    if (_searchQuery.trim().isEmpty) return _allChapters;
    return _allChapters
        .where((ch) => ch.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNoPdfAvailableDialog(BuildContext context, String chapterTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildGlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryAccent.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondaryAccent.withOpacity(0.35)),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppTheme.secondaryAccent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No PDF Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'No Doubt PDF has been uploaded for "$chapterTitle" in the database.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppTheme.glassBorder),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadScreen(
                                initialClass: widget.className,
                                initialSubject: widget.subjectName,
                                initialChapter: chapterTitle,
                              ),
                            ),
                          ).then((_) => _fetchUploadedChaptersFromDatabase());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                        label: const Text(
                          'Upload PDF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final chapters = _filteredChapters;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Custom Glass Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceGlassCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subjectTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${_allChapters.length} Chapters Available',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.accentColor.withOpacity(0.3)),
                      ),
                      child: Icon(widget.icon, color: widget.accentColor, size: 20),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search chapter name...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceGlassCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.glassBorder, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Chapters List
              Expanded(
                child: chapters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No chapters matching "$_searchQuery"',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapterTitle = chapters[index];
                          final chapterIndex = index + 1;
                          final isAvailable = _isPdfAvailable(chapterTitle);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                if (isAvailable) {
                                  String? foundPath = _chapterFilePaths[chapterTitle];
                                  if (foundPath == null) {
                                    final normTitle = chapterTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                                    for (final entry in _chapterFilePaths.entries) {
                                      final normKey = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                                      if (normKey == normTitle || normKey.contains(normTitle) || normTitle.contains(normKey)) {
                                        foundPath = entry.value;
                                        break;
                                      }
                                    }
                                  }

                                  final serverDownloadUrl =
                                      ApiConfig.downloadPdfUrl(chapter: chapterTitle);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(
                                        fileName: '$chapterTitle.pdf',
                                        filePath: serverDownloadUrl,
                                      ),
                                    ),
                                  );
                                } else {
                                  _showNoPdfAvailableDialog(context, chapterTitle);
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: _buildGlassContainer(
                                borderRadius: 18,
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? widget.accentColor.withOpacity(0.15)
                                            : Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isAvailable
                                              ? widget.accentColor.withOpacity(0.3)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        '#$chapterIndex',
                                        style: TextStyle(
                                          color: isAvailable ? widget.accentColor : AppTheme.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapterTitle,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAvailable
                                                      ? const Color(0x3030D158)
                                                      : Colors.white.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isAvailable
                                                        ? const Color(0xFF30D158).withOpacity(0.5)
                                                        : Colors.white.withOpacity(0.12),
                                                  ),
                                                ),
                                                child: Text(
                                                  isAvailable ? 'PDF Available' : 'No PDF',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAvailable
                                                        ? const Color(0xFF30D158)
                                                        : AppTheme.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                                      color: AppTheme.secondaryAccent,
                                      tooltip: 'Upload doubt for this chapter',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UploadScreen(
                                              initialClass: widget.className,
                                              initialSubject: widget.subjectName,
                                              initialChapter: chapterTitle,
                                            ),
                                          ),
                                        ).then((_) => _fetchUploadedChaptersFromDatabase());
                                      },
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textSecondary.withOpacity(0.7),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
