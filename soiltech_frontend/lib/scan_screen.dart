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
  static const bgColor = Colors.white;
  static const darkGreen = Color(0xFF5B922F);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);
  static const cropCardColor = Color(0xFFF5F8D6);

  String _getCropAsset(String crop) {
    final key = crop.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');

    const assetMap = {
      'rice': 'rice.png',
      'corn': 'corn.png',
      'maize': 'corn.png',
      'tomato': 'tomato.png',
      'eggplant': 'eggplant.png',
      'egg_plant': 'eggplant.png',
      'camote': 'kamote.png',
      'sweet_potato': 'kamote.png',
      'pechay': 'petchay.png',
      'petchay': 'petchay.png',
      'cassava': 'cassava.png',
      'kangkong': 'kangkong.png',
      'onion': 'onion.png',
      'garlic': 'garlic.png',
      'mustasa': 'mustasa.png',
      'ampalaya': 'ampalaya.png',
      'alugbati': 'spinach.png',
      'okra': 'okra.png',
      'sitaw': 'sitaw.png',
      'lettuce': 'lettuce.png',
      'sili': 'sili.png',
      'kalamansi': 'calamansi.png',
      'malunggay': 'malunggay.png',
      'tanglad': 'tanglad.png',
      'sayote': 'sayote.png',
      'singkamas': 'singkamas.png',
      'sigarilyas': 'sigarilyas.png',
      'mani': 'mani.png',
      'kundol': 'kundol.png',
      'patola': 'patola.png',
      'upo': 'upo.png',
      'radish': 'radish.png',
      'pipino': 'cucumber.png',
      'cucumber': 'cucumber.png',
      'luya': 'ginger.png',
      'ginger': 'ginger.png',
      'pako': 'pako.png',
      'carrots': 'carrot.png',
      'carrot': 'carrot.png',
      'potato': 'potato.png',
      'chinese_petchay': 'chinese_petchay.png',
      'green_onions': 'green_onions.png',
      'green_onion': 'green_onions.png',
      'repolyo': 'repolyo.png',
      'bokchoy': 'bokchoy.png',
      'papaya': 'papaya.png',
      'baguio_beans': 'baguio_beans.png',
      'monggo': 'monggo.png',
      'turmeric': 'turmeric.png',
      'asthma_plant': 'asthmaplant.png',
      'asthmaplant': 'asthmaplant.png',
      'oregano': 'oregano.png',
      'lagundi': 'lagundi.png',
      'basil': 'basil.png',
      'pandan': 'pandan.png',
      'mint': 'mint.png',
      'ube': 'ube.png',
      'rosemary': 'rosemary.png',
      'chives': 'chives.png',
    };

    return 'assets/logo/${assetMap[key] ?? 'soiltech_logo.png'}';
  }

  String _formatCropName(String crop) {
    return crop
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

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
  }

  Widget _buildNavButtons(double w, double h) {
    final isStep5 = _currentStep == 4;
    final isStep4 = _currentStep == 3;

    final bool canProceed = _currentStep == 0
        ? _selectedCrop != null
        : isStep4
            ? _selectedImage != null
            : isStep5
                ? _predictResult != null
                : true;

    final String rightLabel = isStep5
        ? 'Continue'
        : isStep4
            ? 'Scan Soil'
            : 'Next';

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
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF5B922F),
              ),
              label: const Text(
                'Back',
                style: TextStyle(
                  color: Color(0xFF5B922F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5B922F), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: h * 0.018),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: rightAction,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isStep5
                          ? Icons.check_circle_outline_rounded
                          : isStep4
                              ? Icons.document_scanner_outlined
                              : Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
              label: Text(
                _isScanning ? '' : rightLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? darkGreen : Colors.grey.shade300,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: h * 0.018),
                elevation: canProceed ? 3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required double w,
    required double h,
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: h * 0.015),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        decoration: BoxDecoration(
          color: selected ? darkGreen.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? darkGreen : borderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.11,
              height: w * 0.11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? darkGreen.withOpacity(0.16)
                    : cropCardColor,
              ),
              child: Icon(
                icon,
                color: selected ? darkGreen : const Color(0xFF7D9C74),
                size: w * 0.06,
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w700,
                      color: selected ? darkGreen : textDark,
                    ),
                  ),
                  SizedBox(height: h * 0.004),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCropStep(double w, double h) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.015, w * 0.05, 0),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: w * 0.24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What crop do you want to plant?',
                        style: TextStyle(
                          fontSize: w * 0.07,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0B3D18),
                        ),
                      ),
                      SizedBox(height: h * 0.012),
                      Text(
                        'Tap a crop or search in Tagalog or English.',
                        style: TextStyle(
                          fontSize: w * 0.038,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF506A4D),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: h * 0.005,
                  child: Image.asset(
                    'assets/logo/basket_design.png',
                    width: w * 0.23,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_florist,
                      size: w * 0.18,
                      color: const Color(0xFF80B155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: h * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Container(
              padding: EdgeInsets.all(w * 0.012),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE3E3E3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        color: const Color(0xFF0B3D18),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. palay, mais, kamote...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF4B7B34),
                          size: 30,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: h * 0.019,
                          horizontal: w * 0.02,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDE6B7),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFF80B155),
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: _searchCrop,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  SizedBox(
                    height: h * 0.072,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching
                          ? null
                          : () => _searchCrop(_searchController.text),
                      icon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                      label: Text(
                        _isSearching ? '' : 'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF5B922F),
                        disabledBackgroundColor: const Color(0xFF80B155),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.018),
          Expanded(
            child: _isLoadingCrops
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF80B155),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    child: GridView.builder(
                      padding: EdgeInsets.only(bottom: h * 0.015),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.75,
                      ),
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        final crop = _crops[index];
                        final selected = _selectedCrop == crop;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCrop = crop),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: cropCardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF80B155)
                                    : const Color(0xFFE7DFA7),
                                width: selected ? 2.2 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: selected
                                      ? const Color(0xFF80B155).withOpacity(0.20)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: selected ? 14 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      w * 0.02,
                                      h * 0.012,
                                      w * 0.02,
                                      h * 0.008,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            _getCropAsset(crop),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
                                              'assets/logo/soiltech_logo.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.eco_rounded,
                                                color: Color(0xFF80B155),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: h * 0.004),
                                        Text(
                                          _formatCropName(crop),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: w * 0.038,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF0B3D18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF80B155),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
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
      ),
    );
  }

  Widget _buildSoilConditionStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: w * 0.12,
            color: const Color(0xFF7EC8E3),
          ),
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
            title: 'Wet',
            subtitle: 'Soil is moist, muddy, or waterlogged',
            icon: Icons.water_drop_rounded,
            onTap: () => setState(() => _wetDryScore = -1),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _wetDryScore == 0,
            title: 'Normal',
            subtitle: 'Soil crumbles easily in hand',
            icon: Icons.eco_rounded,
            onTap: () => setState(() => _wetDryScore = 0),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _wetDryScore == 1,
            title: 'Dry',
            subtitle: 'Soil is hard, dusty, or cracked',
            icon: Icons.wb_sunny_outlined,
            onTap: () => setState(() => _wetDryScore = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainageStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.waves_rounded,
            size: w * 0.12,
            color: const Color(0xFF7EC8E3),
          ),
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
            icon: Icons.water_rounded,
            onTap: () => setState(() => _drainageScore = -1),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _drainageScore == 0,
            title: 'Normal absorption',
            subtitle: 'Moderate',
            icon: Icons.grass_rounded,
            onTap: () => setState(() => _drainageScore = 0),
          ),
          _buildOptionCard(
            w: w,
            h: h,
            selected: _drainageScore == 1,
            title: 'Drains very fast',
            subtitle: 'Excessive',
            icon: Icons.bolt_rounded,
            onTap: () => setState(() => _drainageScore = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep(double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: w * 0.12,
            color: darkGreen,
          ),
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
                          'Tap to take a photo',
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          'JPG or PNG - up to 10MB',
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

  Widget _buildScanResultStep(double w, double h) {
    final result = _predictResult;
    if (result == null) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }

    final soilType = result['soil_type'] ?? '-';
    final omLevel = result['om_level'] ?? '-';
    final confidence = result['confidence'] ?? '-';

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
    final safeValue = value.isEmpty ? '-' : value;

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
            safeValue == '-'
                ? '-'
                : safeValue[0].toUpperCase() + safeValue.substring(1),
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
            const Divider(height: 1, color: Color(0xFFE7E1C5)),
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
            const Divider(height: 1, color: Color(0xFFE7E1C5)),
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
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 7,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? const Color(0xFF93C83E)
                    : const Color(0xFFE3E0D0),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepLabel(double w) {
    const labels = [
      'Step 1 of 5 - Choose Your Crop',
      'Step 2 of 5 - Soil Condition',
      'Step 3 of 5 - Drainage',
      'Step 4 of 5 - Take a Photo',
      'Step 5 of 5 - Scan Result',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 10),
      child: Row(
        children: [
          if (_currentStep == 0) ...[
            Image.asset(
              'assets/logo/soiltech_logo.png',
              width: w * 0.075,
              height: w * 0.075,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                color: Color(0xFF80B155),
              ),
            ),
            SizedBox(width: w * 0.025),
          ],
          Expanded(
            child: Text(
              labels[_currentStep],
              style: TextStyle(
                fontSize: w * 0.038,
                color: _currentStep == 0
                    ? const Color(0xFF174D22)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}