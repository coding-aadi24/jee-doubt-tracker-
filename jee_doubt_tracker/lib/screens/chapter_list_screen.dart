import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/chapter_pdf_store.dart';
import '../config/api_config.dart';
import '../widgets/glass_neumorphic_widgets.dart';
import 'pdf_viewer_screen.dart';
import 'upload_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final String subjectTitle; // e.g. "Class 12 — Physics"
  final String className;    // e.g. "Class 12"
  final String subjectName;  // e.g. "Physics"
  final Color accentColor;
  final IconData icon;
  final String? heroTag;

  const ChapterListScreen({
    Key? key,
    required this.subjectTitle,
    required this.className,
    required this.subjectName,
    required this.accentColor,
    required this.icon,
    this.heroTag,
  }) : super(key: key);

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Set<String> _availableChaptersInDb = {};
  Map<String, String> _chapterFilePaths = {};

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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUploadedChaptersFromDatabase() async {
    final Set<String> available = {};
    final Map<String, String> paths = {};

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.uploadsUrl))
          .timeout(const Duration(seconds: 60)); // 60s timeout for Render free tier cold start

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
    } catch (_) {}

    if (mounted) {
      setState(() {
        _availableChaptersInDb = available;
        _chapterFilePaths = paths;
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

  void _showNoPdfAvailableDialog(BuildContext context, String chapterTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassNeumorphicCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            borderColor: AppTheme.secondaryAccent.withOpacity(0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppTheme.secondaryAccent.withOpacity(0.18),
                  borderColor: AppTheme.secondaryAccent.withOpacity(0.35),
                  shadows: const [],
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppTheme.secondaryAccent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: () => Navigator.pop(context),
                        surfaceColor: AppTheme.surfaceNeumorphic,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeumorphicButton(
                        onPressed: () {
                          Navigator.pop(context);
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
                        isGlowing: true,
                        accentColor: AppTheme.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Upload PDF',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    final chapters = _filteredChapters;

    Widget headerContent = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 22,
      child: Row(
        children: [
          NeumorphicIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 38,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_allChapters.length} Chapters in Module',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GlassCard(
            borderRadius: 14,
            padding: const EdgeInsets.all(8),
            backgroundColor: widget.accentColor.withOpacity(0.18),
            borderColor: widget.accentColor.withOpacity(0.35),
            shadows: const [],
            child: Icon(widget.icon, color: widget.accentColor, size: 20),
          ),
        ],
      ),
    );

    if (widget.heroTag != null) {
      headerContent = Hero(
        tag: widget.heroTag!,
        child: Material(
          color: Colors.transparent,
          child: headerContent,
        ),
      );
    }

    return Scaffold(
      body: AmbientBackground(
        scrollController: _scrollController,
        child: SafeArea(
          child: Column(
            children: [
              // Hero Target Navigation Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: headerContent,
              ),

              // Debossed Neumorphic Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: NeumorphicTextField(
                  controller: _searchController,
                  hintText: 'Search chapter by name...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

              const SizedBox(height: 6),

              // Chapters Soft UI Extruded List with Parallax Scroll & Staggered Entrance
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
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapterTitle = chapters[index];
                          final realIdx = _allChapters.indexOf(chapterTitle);
                          final chapterIndex = realIdx != -1 ? realIdx + 1 : index + 1;
                          final isAvailable = _isPdfAvailable(chapterTitle);

                          return StaggeredEntrance(
                            index: index,
                            baseDelayMs: 30,
                            stepDelayMs: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NeumorphicCard(
                                borderRadius: 20,
                                padding: const EdgeInsets.all(14),
                                accentBorderColor: isAvailable
                                    ? widget.accentColor.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.08),
                                onTap: () {
                                  if (isAvailable) {
                                    String? localStorePath = ChapterPdfStore.getChapterPdfPath(
                                      className: widget.className,
                                      subject: widget.subjectName,
                                      chapter: chapterTitle,
                                    );

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

                                    final targetFileUrlOrPath =
                                        localStorePath ?? (foundPath ?? ApiConfig.downloadPdfUrl(chapter: chapterTitle));

                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 400),
                                        pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
                                          fileName: '$chapterTitle.pdf',
                                          filePath: targetFileUrlOrPath,
                                        ),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    _showNoPdfAvailableDialog(context, chapterTitle);
                                  }
                                },
                                child: Row(
                                  children: [
                                    // Chapter Index Soft UI Pill
                                    Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isAvailable
                                            ? widget.accentColor.withOpacity(0.18)
                                            : const Color(0xFF14161E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isAvailable
                                              ? widget.accentColor.withOpacity(0.35)
                                              : Colors.white.withOpacity(0.08),
                                        ),
                                        boxShadow: isAvailable ? [] : AppTheme.neumorphicPressedShadows(),
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              GlassCard(
                                                borderRadius: 8,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                blur: 4,
                                                backgroundColor: isAvailable
                                                    ? AppTheme.accentEmerald.withOpacity(0.18)
                                                    : Colors.white.withOpacity(0.06),
                                                borderColor: isAvailable
                                                    ? AppTheme.accentEmerald.withOpacity(0.4)
                                                    : Colors.white.withOpacity(0.1),
                                                shadows: const [],
                                                child: Text(
                                                  isAvailable ? 'PDF Available' : 'No PDF Uploaded',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAvailable
                                                        ? AppTheme.accentEmerald
                                                        : AppTheme.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    NeumorphicIconButton(
                                      icon: Icons.cloud_upload_outlined,
                                      iconColor: AppTheme.secondaryAccent,
                                      size: 36,
                                      tooltip: 'Upload doubt PDF',
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
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.textMuted.withOpacity(0.7),
                                      size: 20,
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
