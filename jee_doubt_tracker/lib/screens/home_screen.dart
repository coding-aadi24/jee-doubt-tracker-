import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../widgets/glass_neumorphic_widgets.dart';
import 'pdf_viewer_screen.dart';
import 'upload_screen.dart';
import 'chapter_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedClassFilter = 'All'; // 'All', 'Class 11', 'Class 12'
  Map<String, int> _subjectPdfCounts = {};
  int _totalPdfCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPdfCounts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPdfCounts() async {
    final Map<String, int> counts = {};
    int total = 0;

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.uploadsUrl))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final List records = data['data'];
          total = records.length;
          for (var record in records) {
            final cls = record['className']?.toString() ?? '';
            final subj = record['subject']?.toString() ?? '';
            if (cls.isNotEmpty && subj.isNotEmpty) {
              final key = '$cls — $subj';
              counts[key] = (counts[key] ?? 0) + 1;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _subjectPdfCounts = counts;
        _totalPdfCount = total;
      });
    }
  }

  Future<void> _pickAndOpenPdf(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (!context.mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => PdfViewerScreen(
              fileName: file.name,
              filePath: file.path,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PdfViewerScreen(
            fileName: 'Class12_Physics_Rotation_Module.pdf',
            filePath: 'Device Storage / Downloads / Rotation.pdf',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _subjectCollections => [
    {
      'class': 'Class 11',
      'title': 'Class 11 — Physics',
      'color': AppTheme.primaryAccent,
      'icon': Icons.bolt_rounded,
    },
    {
      'class': 'Class 11',
      'title': 'Class 11 — Chemistry',
      'color': AppTheme.secondaryAccent,
      'icon': Icons.science_rounded,
    },
    {
      'class': 'Class 11',
      'title': 'Class 11 — Mathematics',
      'color': AppTheme.accentCyan,
      'icon': Icons.calculate_rounded,
    },
    {
      'class': 'Class 12',
      'title': 'Class 12 — Physics',
      'color': AppTheme.primaryAccent,
      'icon': Icons.functions_rounded,
    },
    {
      'class': 'Class 12',
      'title': 'Class 12 — Chemistry',
      'color': AppTheme.secondaryAccent,
      'icon': Icons.science_rounded,
    },
    {
      'class': 'Class 12',
      'title': 'Class 12 — Mathematics',
      'color': AppTheme.accentCyan,
      'icon': Icons.calculate_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        scrollController: _scrollController,
        child: SafeArea(
          child: Column(
            children: [
              // Floating Glass Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  borderRadius: 22,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryAccent.withOpacity(0.2),
                              border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.4)),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: AppTheme.primaryAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'JEE Doubt Vault',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Collaborative Practice Hub',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      NeumorphicIconButton(
                        icon: Icons.settings_rounded,
                        size: 38,
                        tooltip: 'Vault Settings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 350),
                              pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
                                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          ).then((_) => _fetchPdfCounts());
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Main Scrollable Body with Parallax ScrollController
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Glass Banner with Neumorphic Action Buttons
                      StaggeredEntrance(
                        index: 0,
                        child: GlassCard(
                          borderRadius: 28,
                          padding: const EdgeInsets.all(22.0),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -30,
                                bottom: -30,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryAccent.withOpacity(0.18),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Doubt Organizer Engine',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Open & Read Practice Material',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tag question numbers directly into your team doubt bank with automated cloud sync.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    children: [
                                      NeumorphicButton(
                                        onPressed: () => _pickAndOpenPdf(context),
                                        isGlowing: true,
                                        accentColor: AppTheme.primaryAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Open Local PDF',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      NeumorphicButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              transitionDuration: const Duration(milliseconds: 400),
                                              pageBuilder: (context, animation, secondaryAnimation) => const UploadScreen(),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
                                                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                                  ),
                                                  child: FadeTransition(opacity: animation, child: child),
                                                );
                                              },
                                            ),
                                          ).then((_) => _fetchPdfCounts());
                                        },
                                        accentColor: AppTheme.secondaryAccent,
                                        surfaceColor: AppTheme.surfaceNeumorphic,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cloud_upload_rounded, color: AppTheme.secondaryAccent, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Upload to Drive',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Neumorphic Stats Soft UI Card with Staggered Entrance
                      StaggeredEntrance(
                        index: 1,
                        child: NeumorphicCard(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(20),
                          surfaceColor: AppTheme.surfaceNeumorphic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics_rounded, size: 16, color: AppTheme.primaryAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Collaborative Library Metrics',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('$_totalPdfCount', 'Uploaded PDFs', AppTheme.secondaryAccent),
                                  _buildStatItem('${_subjectPdfCounts.length}', 'Active Modules', AppTheme.primaryAccent),
                                  _buildStatItem('${_subjectCollections.length}', 'Subject Vaults', AppTheme.accentCyan),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Section Title & Filter Chips
                      Text(
                        'Browse Chapter Collections',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Neumorphic Class Filter Chips
                      Row(
                        children: [
                          NeumorphicChip(
                            label: 'All Subjects',
                            isSelected: _selectedClassFilter == 'All',
                            onTap: () => setState(() => _selectedClassFilter = 'All'),
                          ),
                          const SizedBox(width: 10),
                          NeumorphicChip(
                            label: 'Class 11',
                            isSelected: _selectedClassFilter == 'Class 11',
                            onTap: () => setState(() => _selectedClassFilter = 'Class 11'),
                          ),
                          const SizedBox(width: 10),
                          NeumorphicChip(
                            label: 'Class 12',
                            isSelected: _selectedClassFilter == 'Class 12',
                            onTap: () => setState(() => _selectedClassFilter = 'Class 12'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Neumorphic Subject Grid Cards with Hero Morphing & Staggered Animations
                      ..._subjectCollections
                          .asMap()
                          .entries
                          .where((entry) =>
                              _selectedClassFilter == 'All' ||
                              entry.value['class'] == _selectedClassFilter)
                          .map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final title = item['title'] as String;
                            final count = _subjectPdfCounts[title] ?? 0;
                            final countLabel = count == 0 ? '0 PDFs' : '$count PDF${count > 1 ? 's' : ''}';

                            return StaggeredEntrance(
                              index: idx + 2,
                              child: _buildNeumorphicSubjectCard(
                                context: context,
                                title: title,
                                pdfCount: countLabel,
                                color: item['color'] as Color,
                                icon: item['icon'] as IconData,
                                onReturn: _fetchPdfCounts,
                              ),
                            );
                          })
                          .toList(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatItem(String value, String label, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  static Widget _buildNeumorphicSubjectCard({
    required BuildContext context,
    required String title,
    required String pdfCount,
    required Color color,
    required IconData icon,
    VoidCallback? onReturn,
  }) {
    final heroTag = 'subject_hero_$title';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: NeumorphicCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(16),
            accentBorderColor: Colors.white.withOpacity(0.08),
            onTap: () {
              final parts = title.split(' — ');
              final className = parts.isNotEmpty ? parts[0].trim() : 'Class 12';
              final subjectName = parts.length > 1 ? parts[1].trim() : 'Physics';

              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 450),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                  pageBuilder: (context, animation, secondaryAnimation) => ChapterListScreen(
                    subjectTitle: title,
                    className: className,
                    subjectName: subjectName,
                    accentColor: color,
                    icon: icon,
                    heroTag: heroTag,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
                      child: child,
                    );
                  },
                ),
              ).then((_) => onReturn?.call());
            },
            child: Row(
              children: [
                // Frosted Glass Icon Badge
                GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  blur: 8,
                  backgroundColor: color.withOpacity(0.15),
                  borderColor: color.withOpacity(0.30),
                  shadows: const [],
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chapter Question Bank',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Soft UI Pill Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14161E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                    boxShadow: AppTheme.neumorphicPressedShadows(),
                  ),
                  child: Text(
                    pdfCount,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  ),
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
      ),
    );
  }
}
