// lib/widgets/scan_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:soiltech/services/flask_soil_api.dart';
import 'results_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const bgColor = Color(0xFFF1EFEA);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);

  static const Map<String, String> _cropEmojis = {
    'rice': '🌾',
    'corn': '🌽',
    'tomato': '🍅',
    'eggplant': '🍆',
    'camote': '🍠',
    'pechay': '🥬',
    'cassava': '🌿',
    'kangkong': '🍃',
  };

  String _getEmoji(String crop) => _cropEmojis[crop] ?? '🌱';

  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  List<String> _crops = [];
  String? _selectedCrop;
  bool _isLoadingCrops = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  int _wetDryScore = 0;
  int _drainageScore = 0;

  File? _selectedImage;
  bool _isScanning = false;

  Map<String, dynamic>? _predictResult;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Load crops ─────────────────────────────────────────────

  Future<void> _loadCrops() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/crops'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _crops = List<String>.from(data['crops']);
          _isLoadingCrops = false;
        });
      }
    } catch (_) {
      setState(() {
        _crops = [
          'rice',
          'corn',
          'tomato',
          'eggplant',
          'camote',
          'pechay',
          'cassava',
          'kangkong',
        ];
        _isLoadingCrops = false;
      });
    }
  }

  // ── Crop search ────────────────────────────────────────────

  Future<void> _searchCrop(String input) async {
    if (input.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/normalize-crop'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'crop_name': input.trim()}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matched = data['crop'] as String?;
        if (matched != null && _crops.contains(matched)) {
          setState(() => _selectedCrop = matched);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Matched: ${matched[0].toUpperCase()}${matched.substring(1)}',
                ),
                backgroundColor: darkGreen,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No matching crop found. Try another name.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // ── Navigation ─────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _runScan() async {
    if (_selectedImage == null || _selectedCrop == null) return;
    setState(() => _isScanning = true);
    try {
      final result = await SoilApi.predict(_selectedImage!, _wetDryScore);
      setState(() => _predictResult = result);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan error: $e')));
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _goToResults() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          predictResult: _predictResult!,
          imageFile: _selectedImage!,
          cropName: _selectedCrop!,
          drainageScore: _drainageScore,
        ),
      ),
    );
    // Back from ResultsScreen lands here on Step 5 — no action needed.
  }

  // ══════════════════════════════════════════════════════════════
  // NAV BAR — same position for ALL 5 steps
  // ══════════════════════════════════════════════════════════════

  Widget _buildNavButtons(double w, double h) {
    final isStep5 = _currentStep == 4;
    final isStep4 = _currentStep == 3;

    // Right button label / action
    final bool canProceed = _currentStep == 0
        ? _selectedCrop != null
        : isStep4
        ? _selectedImage != null
        : isStep5
        ? _predictResult != null
        : true;

    final String rightLabel = isStep5
        ? 'Continue →'
        : isStep4
        ? 'Scan Soil →'
        : 'Next →';

    final VoidCallback? rightAction = canProceed
        ? isStep5
              ? _goToResults
              : isStep4
              ? _runScan
              : _nextStep
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
      child: Row(
        children: [
          // ← Back — always shown
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: h * 0.018),
              ),
              child: const Text('← Back', style: TextStyle(color: darkGreen)),
            ),
          ),
          SizedBox(width: w * 0.03),
          // Next / Scan Soil / Continue
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: rightAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? darkGreen : Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: h * 0.018),
                elevation: 0,
              ),
              child: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      rightLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SHARED OPTION CARD
  // ══════════════════════════════════════════════════════════════

  Widget _buildOptionCard({
    required double w,
    required double h,
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: h * 0.015),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        decoration: BoxDecoration(
          color: selected ? darkGreen.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? darkGreen : borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? darkGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: selected ? darkGreen : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            SizedBox(width: w * 0.04),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w600,
                    color: selected ? darkGreen : textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1 — CROP
  // ══════════════════════════════════════════════════════════════

  Widget _buildCropStep(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌱', style: TextStyle(fontSize: w * 0.12)),
              SizedBox(height: h * 0.01),
              Text(
                'What crop do you want to plant?',
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              SizedBox(height: h * 0.005),
              Text(
                'Tap a crop or search in Tagalog or English.',
                style: TextStyle(
                  fontSize: w * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: h * 0.015),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'e.g. palay, mais, kamote...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: darkGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: darkGreen,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _searchCrop,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSearching
                          ? null
                          : () => _searchCrop(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Search',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.02),
        Expanded(
          child: _isLoadingCrops
              ? const Center(child: CircularProgressIndicator(color: darkGreen))
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                    itemCount: _crops.length,
                    itemBuilder: (context, index) {
                      final crop = _crops[index];
                      final selected = _selectedCrop == crop;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCrop = crop),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? darkGreen : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? darkGreen : borderColor,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: darkGreen.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getEmoji(crop),
                                style: TextStyle(fontSize: w * 0.09),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                crop[0].toUpperCase() + crop.substring(1),
                                style: TextStyle(
                                  fontSize: w * 0.038,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2 — SOIL CONDITION
  // ══════════════════════════════════════════════════════════════

  Widget _buildSoilConditionStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💧', style: TextStyle(fontSize: w * 0.12)),
          SizedBox(height: h * 0.01),
          Text(
            'How is your soil right now?',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: h * 0.005),
          Text(
            'This helps us read your soil photo accurately.',
            style: TextStyle(fontSize: w * 0.035, color: Colors.grey.shade600),
          ),
          SizedBox(height: h * 0.025),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _wetDryScore == -1,
            title: 'Wet 💧',
            subtitle: 'Soil is moist, muddy, or waterlogged',
            onTap: () => setState(() => _wetDryScore = -1),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _wetDryScore == 0,
            title: 'Normal 🌿',
            subtitle: 'Soil crumbles easily in hand',
            onTap: () => setState(() => _wetDryScore = 0),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _wetDryScore == 1,
            title: 'Dry ☀️',
            subtitle: 'Soil is hard, dusty, or cracked',
            onTap: () => setState(() => _wetDryScore = 1),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3 — DRAINAGE
  // ══════════════════════════════════════════════════════════════

  Widget _buildDrainageStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌊', style: TextStyle(fontSize: w * 0.12)),
          SizedBox(height: h * 0.01),
          Text(
            'How does water behave in your soil?',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: h * 0.005),
          Text(
            'Observe after a heavy rain or watering.',
            style: TextStyle(fontSize: w * 0.035, color: Colors.grey.shade600),
          ),
          SizedBox(height: h * 0.025),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _drainageScore == -1,
            title: 'Water pools and stays',
            subtitle: 'Poor drainage',
            onTap: () => setState(() => _drainageScore = -1),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _drainageScore == 0,
            title: 'Normal absorption',
            subtitle: 'Moderate',
            onTap: () => setState(() => _drainageScore = 0),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _drainageScore == 1,
            title: 'Drains very fast ⚡',
            subtitle: 'Excessive',
            onTap: () => setState(() => _drainageScore = 1),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4 — PHOTO
  // ══════════════════════════════════════════════════════════════

  Widget _buildPhotoStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📷', style: TextStyle(fontSize: w * 0.12)),
          SizedBox(height: h * 0.01),
          Text(
            'Scan your soil',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: h * 0.005),
          Text(
            'Take a clear close-up photo of your soil surface.',
            style: TextStyle(fontSize: w * 0.035, color: Colors.grey.shade600),
          ),
          SizedBox(height: h * 0.025),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              height: h * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: w * 0.1,
                          color: darkGreen,
                        ),
                        SizedBox(height: h * 0.01),
                        Text(
                          '📷 Tap to take a photo',
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          'JPG or PNG • up to 10MB',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: h * 0.015),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          SizedBox(height: h * 0.015),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, color: darkGreen),
              label: const Text(
                'Upload from gallery',
                style: TextStyle(color: darkGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: h * 0.018),
              ),
            ),
          ),
          if (_selectedImage != null) ...[
            SizedBox(height: h * 0.015),
            Row(
              children: [
                const Icon(Icons.check_circle, color: darkGreen, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedImage!.path.split('/').last,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: darkGreen,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 5 — SCAN RESULT PREVIEW
  // Buttons are NOT here — they live in _buildNavButtons below
  // ══════════════════════════════════════════════════════════════

  Widget _buildScanResultStep(double w, double h) {
    final result = _predictResult;
    if (result == null) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }

    final soilType = result['soil_type'] ?? '—';
    final omLevel = result['om_level'] ?? '—';
    final confidence = result['confidence'] ?? '—';

    Color chipColor(String value) {
      switch (value.toLowerCase()) {
        case 'high':
          return Colors.green.shade600;
        case 'moderate':
          return Colors.orange.shade600;
        case 'low':
          return Colors.red.shade400;
        default:
          return darkGreen;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h * 0.01),
          Container(
            width: w * 0.18,
            height: w * 0.18,
            decoration: const BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          SizedBox(height: h * 0.02),
          Text(
            'Soil Scan Complete',
            style: TextStyle(
              fontSize: w * 0.06,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          SizedBox(height: h * 0.005),
          Text(
            "Here's what we found in your sample.",
            style: TextStyle(fontSize: w * 0.035, color: Colors.grey.shade500),
          ),
          SizedBox(height: h * 0.025),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: h * 0.25,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: h * 0.025),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _resultRow(w, Icons.layers, 'Soil Type', soilType, darkGreen),
                const Divider(height: 20),
                _resultRow(
                  w,
                  Icons.eco,
                  'Organic Matter',
                  omLevel,
                  chipColor(omLevel),
                ),
                const Divider(height: 20),
                _resultRow(
                  w,
                  Icons.bar_chart,
                  'Confidence',
                  confidence,
                  darkGreen,
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.02),
        ],
      ),
    );
  }

  Widget _resultRow(
    double w,
    IconData icon,
    String label,
    String value,
    Color chipColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: w * 0.05, color: Colors.grey.shade500),
            SizedBox(width: w * 0.03),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.038,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value[0].toUpperCase() + value.substring(1),
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w700,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.02),
            _buildProgressBar(w),
            _buildStepLabel(w),
            const Divider(height: 1),
            SizedBox(height: h * 0.02),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildCropStep(w, h),
                  _buildSoilConditionStep(w, h),
                  _buildDrainageStep(w, h),
                  _buildPhotoStep(w, h),
                  _buildScanResultStep(w, h),
                ],
              ),
            ),
            const Divider(height: 1),
            // ← Single nav bar, same vertical position for all 5 steps
            _buildNavButtons(w, h),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              decoration: BoxDecoration(
                color: i <= _currentStep ? darkGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepLabel(double w) {
    const labels = [
      'Step 1 of 5 — Choose Your Crop',
      'Step 2 of 5 — Soil Condition',
      'Step 3 of 5 — Drainage',
      'Step 4 of 5 — Take a Photo',
      'Step 5 of 5 — Scan Result',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 8),
      child: Text(
        labels[_currentStep],
        style: TextStyle(
          fontSize: w * 0.035,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
