import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import 'pdf_viewer_screen.dart';
import 'upload_screen.dart';
import 'chapter_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedClassFilter = 'All'; // 'All', 'Class 11', 'Class 12'
  Map<String, int> _subjectPdfCounts = {};
  int _totalPdfCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPdfCounts();
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
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              fileName: file.name,
              filePath: file.path,
            ),
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

  final List<Map<String, dynamic>> _subjectCollections = const [
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedClassFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClassFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceGlassCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : AppTheme.glassBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
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
              const SizedBox(height: 12),

              // Main Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary Electric Blue & Warm Amber Hero Banner
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: AppTheme.primaryGradient,
                          boxShadow: AppTheme.glassShadow,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.secondaryAccent.withOpacity(0.25),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'JEE Doubt Vault',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Open & Read Practice Material',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Flag unsolved question pages directly into your group doubt bank.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _pickAndOpenPdf(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: AppTheme.primaryAccent,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryAccent, size: 18),
                                              label: const Text(
                                                'Open PDF',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const UploadScreen(),
                                                  ),
                                                ).then((_) => _fetchPdfCounts());
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.secondaryAccent,
                                                foregroundColor: Colors.black,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.black, size: 18),
                                              label: const Text(
                                                'Upload to Drive',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      size: 42,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dark Glass Stats Overview Container (#1C1C1E Surface)
                      _buildGlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collaborative Doubt Library',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
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

                      const SizedBox(height: 28),

                      // Section Title with Filter Chips
                      const Text(
                        'Browse Chapter Collections',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Pills Row
                      Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Class 11'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Class 12'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Glass Subject Cards (#1C1C1E Surface)
                      ..._subjectCollections
                          .where((item) =>
                              _selectedClassFilter == 'All' ||
                              item['class'] == _selectedClassFilter)
                          .map((item) {
                            final title = item['title'] as String;
                            final count = _subjectPdfCounts[title] ?? 0;
                            final countLabel = count == 0 ? '0 Doubt PDFs' : '$count Doubt PDF${count > 1 ? 's' : ''}';

                            return _buildGlassSubjectTile(
                              context: context,
                              title: title,
                              subtitle: item['subtitle'] as String?,
                              pdfCount: countLabel,
                              color: item['color'] as Color,
                              icon: item['icon'] as IconData,
                              onReturn: _fetchPdfCounts,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _pickAndOpenPdf(context),
          backgroundColor: AppTheme.primaryAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.file_open_rounded, color: Colors.white),
          label: const Text(
            'Open PDF',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  static Widget _buildGlassContainer({
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  static Widget _buildGlassSubjectTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required String pdfCount,
    required Color color,
    required IconData icon,
    VoidCallback? onReturn,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () {
          final parts = title.split(' — ');
          final className = parts.isNotEmpty ? parts[0].trim() : 'Class 12';
          final subjectName = parts.length > 1 ? parts[1].trim() : 'Physics';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapterListScreen(
                subjectTitle: title,
                className: className,
                subjectName: subjectName,
                accentColor: color,
                icon: icon,
              ),
            ),
          ).then((_) => onReturn?.call());
        },
        borderRadius: BorderRadius.circular(20),
        child: _buildGlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pdfCount,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
