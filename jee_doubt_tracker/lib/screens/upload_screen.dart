import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/chapter_pdf_store.dart';
import '../config/api_config.dart';

class UploadScreen extends StatefulWidget {
  final String? initialFilePath;
  final String? initialFileName;
  final int? selectedPageNumber;
  final String? initialClass;
  final String? initialSubject;
  final String? initialChapter;

  const UploadScreen({
    super.key,
    this.initialFilePath,
    this.initialFileName,
    this.selectedPageNumber,
    this.initialClass,
    this.initialSubject,
    this.initialChapter,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // Selections
  String _selectedClass = 'Class 12';
  String _selectedSubject = 'Physics';
  String? _selectedChapter;
  PlatformFile? _selectedFile;

  // User details
  final TextEditingController _userNameController = TextEditingController(text: 'JEE Aspirant');
  final TextEditingController _userEmailController = TextEditingController(text: 'aspirant@jee.edu');
  final TextEditingController _serverUrlController = TextEditingController(text: ApiConfig.baseUrl);

  // UI state
  bool _isUploading = false;
  String? _errorMessage;
  Map<String, dynamic>? _uploadResult;

  final List<String> _classes = ['Class 11', 'Class 12'];

  final Map<String, Map<String, List<String>>> _chaptersByClassAndSubject = {
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

  List<String> get _currentAvailableChapters {
    return _chaptersByClassAndSubject[_selectedClass]?[_selectedSubject] ?? [];
  }

  late final TextEditingController _pageNumberController = TextEditingController(
    text: widget.selectedPageNumber != null ? widget.selectedPageNumber.toString() : '',
  );

  @override
  void initState() {
    super.initState();

    if (widget.initialClass != null && _classes.contains(widget.initialClass)) {
      _selectedClass = widget.initialClass!;
    }
    if (widget.initialSubject != null &&
        _chaptersByClassAndSubject[_selectedClass]?.containsKey(widget.initialSubject) == true) {
      _selectedSubject = widget.initialSubject!;
    }

    final chapters = _currentAvailableChapters;
    if (widget.initialChapter != null && chapters.contains(widget.initialChapter)) {
      _selectedChapter = widget.initialChapter!;
    } else {
      _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
    }

    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      try {
        final file = File(widget.initialFilePath!);
        final size = file.existsSync() ? file.lengthSync() : 0;
        _selectedFile = PlatformFile(
          name: widget.initialFileName ?? file.path.split(Platform.pathSeparator).last,
          path: widget.initialFilePath,
          size: size,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pageNumberController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _onClassChanged(String? newClass) {
    if (newClass == null) return;
    setState(() {
      _selectedClass = newClass;
      final availableSubjects = _chaptersByClassAndSubject[newClass]?.keys.toList() ?? ['Physics', 'Chemistry', 'Mathematics'];
      if (!availableSubjects.contains(_selectedSubject)) {
        _selectedSubject = availableSubjects.isNotEmpty ? availableSubjects.first : 'Physics';
      }
      final chapters = _chaptersByClassAndSubject[newClass]?[_selectedSubject] ?? [];
      _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
    });
  }

  void _onSubjectChanged(String? newSubject) {
    if (newSubject == null) return;
    setState(() {
      _selectedSubject = newSubject;
      final chapters = _chaptersByClassAndSubject[_selectedClass]?[newSubject] ?? [];
      _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
    });
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _showPdfExistsDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.secondaryAccent.withOpacity(0.5), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.secondaryAccent, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Doubt PDF Already Exists!',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '$message\n\nWould you like to save this selected page into the existing Doubt PDF container on Google Drive & PostgreSQL database?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _uploadFileToDriveBackend(forceAppend: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.black),
            label: const Text('Save in Existing Doubt PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _safeJsonDecode(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'message': body};
    } catch (_) {
      return {'error': 'Server returned invalid response format: $body'};
    }
  }

  Future<void> _uploadFileToDriveBackend({bool forceAppend = false}) async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a PDF file first.';
      });
      return;
    }

    if (_selectedChapter == null || _selectedChapter!.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a chapter.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadResult = null;
    });

    try {
      final uri = Uri.parse(ApiConfig.uploadToDriveUrl);

      final request = http.MultipartRequest('POST', uri);
      request.fields['className'] = _selectedClass;
      request.fields['subject'] = _selectedSubject;
      request.fields['chapter'] = _selectedChapter!;
      request.fields['userName'] = _userNameController.text.trim();
      request.fields['userEmail'] = _userEmailController.text.trim();

      final pageText = _pageNumberController.text.trim();
      if (pageText.isNotEmpty) {
        request.fields['pageNumber'] = pageText;
      }
      if (forceAppend) {
        request.fields['forceAppend'] = 'true';
      }

      if (_selectedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'pdfFile',
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ));
      } else if (_selectedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'pdfFile',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ));
      } else {
        throw Exception('File path or bytes not available for upload');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_selectedFile?.path != null) {
          ChapterPdfStore.registerChapterPdf(
            className: _selectedClass,
            subject: _selectedSubject,
            chapter: _selectedChapter!,
            filePath: _selectedFile!.path!,
          );
        }
        setState(() {
          _uploadResult = responseData;
          _isUploading = false;
        });
      } else if (response.statusCode == 409) {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          _showPdfExistsDialog(context, responseData['message'] ?? 'Doubt PDF already exists for this chapter.');
        }
      } else {
        setState(() {
          _errorMessage = responseData['error'] ?? responseData['message'] ?? 'Upload failed with status ${response.statusCode}';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e. Ensure server is reachable at ${ApiConfig.baseUrl}';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableChapters = _currentAvailableChapters;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Upload Doubt PDF',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // Step 1: Select Taxonomy (Class -> Subject -> Chapter)
              _buildSectionCard(
                title: '1. Select Taxonomy',
                icon: Icons.account_tree_rounded,
                child: Column(
                  children: [
                    // Class Dropdown
                    _buildDropdown(
                      label: 'Class',
                      value: _selectedClass,
                      items: _classes,
                      onChanged: _onClassChanged,
                    ),
                    const SizedBox(height: 14),

                    // Subject Dropdown
                    _buildDropdown(
                      label: 'Subject',
                      value: _selectedSubject,
                      items: const ['Physics', 'Chemistry', 'Mathematics'],
                      onChanged: _onSubjectChanged,
                    ),
                    const SizedBox(height: 14),

                    // Chapter Dropdown
                    _buildDropdown(
                      label: 'Chapter Name',
                      value: availableChapters.contains(_selectedChapter) ? _selectedChapter : availableChapters.firstOrNull,
                      items: availableChapters,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedChapter = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Step 2: User Information
              _buildSectionCard(
                title: '2. User Information',
                icon: Icons.person_rounded,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _userNameController,
                      label: 'User Name',
                      icon: Icons.badge_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _userEmailController,
                      label: 'User Email',
                      icon: Icons.email_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Step 3: Pick PDF & Server URL
              _buildSectionCard(
                title: '3. Choose PDF File',
                icon: Icons.picture_as_pdf_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _pickPdfFile,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedFile != null
                              ? AppTheme.primaryAccent.withOpacity(0.12)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedFile != null
                                ? AppTheme.primaryAccent
                                : AppTheme.glassBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selectedFile != null
                                    ? AppTheme.primaryAccent
                                    : AppTheme.surfaceCard,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile != null
                                        ? _selectedFile!.name
                                        : 'Tap to select PDF file',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFile != null
                                        ? '${((_selectedFile!.size > 0 ? _selectedFile!.size : (_selectedFile!.bytes?.length ?? 0)) / (1024 * 1024)).toStringAsFixed(2)} MB'
                                        : 'Supports PDF format up to 50MB',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _pageNumberController,
                      label: 'Page Number to Extract (Optional)',
                      icon: Icons.find_in_page_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Upload Action Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFileToDriveBackend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: AppTheme.primaryAccent.withOpacity(0.4),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 22),
                label: Text(
                  _isUploading ? 'Uploading via Traffic Controller...' : 'Upload to Google Drive & Save DB',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 24),

              // Results Display / Success Card
              if (_uploadResult != null) _buildSuccessCard(_uploadResult!),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final pageNum = widget.selectedPageNumber;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBlueBorder, width: 1.5),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: pageNum != null ? AppTheme.secondaryGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(pageNum != null ? Icons.bookmark_add_rounded : Icons.alt_route_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageNum != null ? 'Flag Page $pageNum for Doubt Bank' : 'Doubt PDF Upload Engine',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  pageNum != null
                      ? 'Sends Page $pageNum parameter to server engine to extract & append to Chapter Doubt PDF.'
                      : 'Upload PDF to Google Drive API & save returned File ID into PostgreSQL DB.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceGlassCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.secondaryAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryAccent),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryAccent, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard(Map<String, dynamic> result) {
    final data = result['data'] ?? {};
    final message = result['message'] ?? 'Doubt page saved successfully!';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlassCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1.5),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doubt Saved Successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 14),

          _buildResultDetailRow('Class', data['className']?.toString() ?? 'N/A'),
          _buildResultDetailRow('Subject', data['subject']?.toString() ?? 'N/A'),
          _buildResultDetailRow('Chapter', data['chapter']?.toString() ?? 'N/A'),
          _buildResultDetailRow('Target File', data['fileName']?.toString() ?? 'N/A'),
          _buildResultDetailRow('Saved By', '${data['userName'] ?? ''} (${data['userEmail'] ?? ''})'),
        ],
      ),
    );
  }

  Widget _buildResultDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
