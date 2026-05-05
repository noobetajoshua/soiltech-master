// lib/widgets/scan_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:soiltech/services/flask_soil_api.dart';

import 'results_screen.dart';
//sjdskdjskjdksdj

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const bgColor = Colors.white;

  static const primaryGreen = Color(0xFFC1D95C);
  static const secondaryGreen = Color(0xFF80B155);
  static const darkGreen = Color(0xFF2F5E1A);

  static const borderColor = Color(0xFF80B155);
  static const textDark = Color(0xFF0A2418);
  static const cropCardColor = Color(0xFFF5F8D6);
  static const cream = Color(0xFFF8F3D9);

  static const int _soilNotSelected = 99;
  static const int _drainageNotSelected = 99;

  static const String stepsBgAsset = 'assets/logo/steps_bg.png';
  static const String step2ImageAsset = 'assets/logo/step2_image.png';
  static const String step3ImageAsset = 'assets/logo/step3_image.png';
  static const String step4ImageAsset = 'assets/logo/step4_image.png';
  static const String step5ImageAsset = 'assets/logo/step5_image.png';

  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  int _currentStep = 0;
  static const int _totalSteps = 5;

  List<String> _crops = [];
  String? _selectedCrop;
  bool _isLoadingCrops = true;
  bool _isSearching = false;

  int _wetDryScore = _soilNotSelected;
  int _drainageScore = _drainageNotSelected;

  File? _selectedImage;
  bool _isScanning = false;
  bool _isPickingImage = false;

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

  // =========================
  // ASSET HELPERS
  // =========================

  String _getCropAsset(String crop) {
    final key =
        crop.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');

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

  // =========================
  // DATA / BACKEND LOGIC
  // =========================

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
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image picker error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      } else {
        _isPickingImage = false;
      }
    }
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

  // =========================
  // BUTTON HELPERS
  // =========================

  BoxDecoration _greenGradientDecoration({
    required double radius,
    bool enabled = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: enabled
          ? const LinearGradient(
              colors: [
                Color(0xFFC1D95C),
                Color(0xFF80B155),
                Color(0xFF2F5E1A),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade300,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
      boxShadow: enabled
          ? [
              BoxShadow(
                color: darkGreen.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ]
          : [],
    );
  }

  Widget _gradientButton({
    required double height,
    required String label,
    required VoidCallback? onTap,
    IconData? leftIcon,
    IconData? rightIcon,
    Widget? customLeading,
    bool isLoading = false,
    double radius = 22,
    double fontSize = 17,
  }) {
    final enabled = onTap != null && !isLoading;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: _greenGradientDecoration(
          radius: radius,
          enabled: enabled,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customLeading != null) ...[
                      customLeading,
                      const SizedBox(width: 8),
                    ] else if (leftIcon != null) ...[
                      Icon(
                        leftIcon,
                        color: Colors.white,
                        size: fontSize + 6,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: fontSize,
                      ),
                    ),
                    if (rightIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        rightIcon,
                        color: Colors.white,
                        size: fontSize + 7,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _outlinedGreenButton({
    required double height,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    double radius = 22,
    double fontSize = 16,
  }) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(
                icon,
                color: darkGreen,
              ),
        label: Text(
          label,
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.94),
          side: const BorderSide(
            color: darkGreen,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  // =========================
  // SHARED WIDGETS
  // =========================

  Widget _buildNavButtons(double w, double h) {
    final isStep5 = _currentStep == 4;
    final isStep4 = _currentStep == 3;

    final bool canProceed = _currentStep == 0
        ? _selectedCrop != null
        : _currentStep == 1
            ? _wetDryScore != _soilNotSelected
            : _currentStep == 2
                ? _drainageScore != _drainageNotSelected
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
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.012, w * 0.05, h * 0.018),
      child: Row(
        children: [
          Expanded(
            child: _outlinedGreenButton(
              height: h * 0.068,
              label: 'Back',
              onTap: _prevStep,
              icon: Icons.arrow_back_rounded,
              radius: 22,
              fontSize: 16,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            flex: 2,
            child: _gradientButton(
              height: h * 0.068,
              label: rightLabel,
              onTap: rightAction,
              isLoading: _isScanning,
              rightIcon: isStep5
                  ? Icons.check_circle_outline_rounded
                  : isStep4
                      ? Icons.document_scanner_outlined
                      : Icons.arrow_forward_rounded,
              radius: 22,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required double w,
    required double h,
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: h * 0.112,
        margin: EdgeInsets.only(bottom: h * 0.010),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.010,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5F8D6).withOpacity(0.96)
              : Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? darkGreen : const Color(0xFFE2E8C9),
            width: selected ? 2.2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? darkGreen.withOpacity(0.14)
                  : Colors.black.withOpacity(0.045),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.115,
              height: w * 0.115,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: w * 0.060,
              ),
            ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.047,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: h * 0.003),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.031,
                      height: 1.15,
                      color: const Color(0xFF66705E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.015),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: w * 0.060,
              height: w * 0.060,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? darkGreen : Colors.transparent,
                border: Border.all(
                  color: selected ? darkGreen : const Color(0xFFB9C4A9),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepImage({
    required double w,
    required String asset,
    required IconData fallbackIcon,
    required Color fallbackColor,
  }) {
    return Image.asset(
      asset,
      width: w * 0.31,
      height: w * 0.31,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        color: fallbackColor,
        size: w * 0.19,
      ),
    );
  }

  Widget _stepTitle({
    required double w,
    required String title,
  }) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: w * 0.064,
        fontWeight: FontWeight.w900,
        height: 1.04,
        color: textDark,
      ),
    );
  }

  Widget _stepSubtitle({
    required double w,
    required String subtitle,
  }) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: w * 0.036,
        height: 1.15,
        color: const Color(0xFF5E6B58),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // =========================
  // STEP 1
  // =========================

  Widget _buildCropStep(double w, double h) {
    return Container(
      color: Colors.transparent,
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
                      color: secondaryGreen,
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
                color: Colors.white.withOpacity(0.94),
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
                        fillColor: Colors.white.withOpacity(0.94),
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
                            color: secondaryGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: _searchCrop,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  SizedBox(
                    width: w * 0.285,
                    child: _gradientButton(
                      height: h * 0.072,
                      label: 'Search',
                      onTap: _isSearching
                          ? null
                          : () => _searchCrop(_searchController.text),
                      isLoading: _isSearching,
                      leftIcon: Icons.search_rounded,
                      radius: 18,
                      fontSize: w * 0.038,
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
                      color: secondaryGreen,
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
                              color: cropCardColor.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? secondaryGreen
                                    : const Color(0xFFE7DFA7),
                                width: selected ? 2.2 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: selected
                                      ? secondaryGreen.withOpacity(0.20)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                color: secondaryGreen,
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
                                        color: secondaryGreen,
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

  // =========================
  // STEP 2
  // =========================

  Widget _buildSoilConditionStep(double w, double h) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          w * 0.05,
          h * 0.002,
          w * 0.05,
          h * 0.004,
        ),
        child: Column(
          children: [
            _stepImage(
              w: w,
              asset: step2ImageAsset,
              fallbackIcon: Icons.water_drop_rounded,
              fallbackColor: const Color(0xFF69B7F0),
            ),
            SizedBox(height: h * 0.006),
            _stepTitle(
              w: w,
              title: 'How is your soil right now?',
            ),
            SizedBox(height: h * 0.006),
            _stepSubtitle(
              w: w,
              subtitle: 'This helps us read your soil photo accurately.',
            ),
            SizedBox(height: h * 0.014),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _wetDryScore == -1,
              title: 'Wet',
              subtitle: 'Soil is moist, muddy, or waterlogged',
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF69B7F0),
              iconBgColor: const Color(0xFFEAF5FF),
              onTap: () => setState(() => _wetDryScore = -1),
            ),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _wetDryScore == 0,
              title: 'Normal',
              subtitle: 'Soil crumbles easily in hand',
              icon: Icons.eco_rounded,
              iconColor: secondaryGreen,
              iconBgColor: const Color(0xFFF0F7DD),
              onTap: () => setState(() => _wetDryScore = 0),
            ),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _wetDryScore == 1,
              title: 'Dry',
              subtitle: 'Soil is hard, dusty, or cracked',
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFF3BC1C),
              iconBgColor: const Color(0xFFFFF5D8),
              onTap: () => setState(() => _wetDryScore = 1),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // =========================
  // STEP 3
  // =========================

  Widget _buildDrainageStep(double w, double h) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          w * 0.05,
          h * 0.002,
          w * 0.05,
          h * 0.004,
        ),
        child: Column(
          children: [
            _stepImage(
              w: w,
              asset: step3ImageAsset,
              fallbackIcon: Icons.waves_rounded,
              fallbackColor: const Color(0xFF7EC8E3),
            ),
            SizedBox(height: h * 0.006),
            _stepTitle(
              w: w,
              title: 'How does water behave in your soil?',
            ),
            SizedBox(height: h * 0.006),
            _stepSubtitle(
              w: w,
              subtitle: 'Observe after a heavy rain or watering.',
            ),
            SizedBox(height: h * 0.014),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _drainageScore == -1,
              title: 'Water pools and stays',
              subtitle: 'Poor drainage',
              icon: Icons.water_rounded,
              iconColor: const Color(0xFF69B7F0),
              iconBgColor: const Color(0xFFEAF5FF),
              onTap: () => setState(() => _drainageScore = -1),
            ),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _drainageScore == 0,
              title: 'Normal absorption',
              subtitle: 'Moderate drainage',
              icon: Icons.grass_rounded,
              iconColor: secondaryGreen,
              iconBgColor: const Color(0xFFF0F7DD),
              onTap: () => setState(() => _drainageScore = 0),
            ),
            _buildChoiceCard(
              w: w,
              h: h,
              selected: _drainageScore == 1,
              title: 'Drains very fast',
              subtitle: 'Excessive drainage',
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFF3BC1C),
              iconBgColor: const Color(0xFFFFF5D8),
              onTap: () => setState(() => _drainageScore = 1),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // =========================
  // STEP 4
  // =========================

  Widget _buildPhotoStep(double w, double h) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _stepImage(
              w: w,
              asset: step4ImageAsset,
              fallbackIcon: Icons.photo_camera_outlined,
              fallbackColor: darkGreen,
            ),
            SizedBox(height: h * 0.006),
            _stepTitle(
              w: w,
              title: 'Scan your soil',
            ),
            SizedBox(height: h * 0.006),
            _stepSubtitle(
              w: w,
              subtitle: 'Take a clear close-up photo of your soil surface.',
            ),
            SizedBox(height: h * 0.018),
            GestureDetector(
              onTap:
                  _isPickingImage ? null : () => _pickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                height: h * 0.19,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
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
                            size: w * 0.095,
                            color: darkGreen,
                          ),
                          SizedBox(height: h * 0.008),
                          Text(
                            'Tap to take a photo',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w800,
                              color: darkGreen,
                            ),
                          ),
                          SizedBox(height: h * 0.004),
                          Text(
                            'JPG or PNG - up to 10MB',
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: h * 0.010),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            SizedBox(height: h * 0.010),
            _gradientButton(
              height: h * 0.062,
              label: 'Upload from gallery',
              onTap: _isPickingImage
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              leftIcon: Icons.photo_library_outlined,
              radius: 18,
              fontSize: 16,
            ),
            if (_selectedImage != null) ...[
              SizedBox(height: h * 0.010),
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
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // =========================
  // STEP 5
  // =========================

  Widget _buildScanResultStep(double w, double h) {
    final result = _predictResult;
    if (result == null) {
      return const Center(
        child: CircularProgressIndicator(color: darkGreen),
      );
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _stepImage(
              w: w,
              asset: step5ImageAsset,
              fallbackIcon: Icons.check_circle_rounded,
              fallbackColor: darkGreen,
            ),
            SizedBox(height: h * 0.006),
            _stepTitle(
              w: w,
              title: 'Soil Scan Complete',
            ),
            SizedBox(height: h * 0.006),
            _stepSubtitle(
              w: w,
              subtitle: "Here's what we found in your sample.",
            ),
            SizedBox(height: h * 0.016),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: h * 0.16,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: h * 0.014),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.045),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _resultRow(w, Icons.layers, 'Soil Type', soilType, darkGreen),
                  const Divider(height: 16),
                  _resultRow(
                    w,
                    Icons.eco,
                    'Organic Matter',
                    omLevel,
                    chipColor(omLevel),
                  ),
                  const Divider(height: 16),
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
            const Spacer(),
          ],
        ),
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

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              stepsBgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.015),
                _buildProgressBar(w),
                _buildStepLabel(w),
                const Divider(height: 1, color: Color(0x55EDE8D7)),
                SizedBox(height: h * 0.006),
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
                const Divider(height: 1, color: Color(0x55EDE8D7)),
                _buildNavButtons(w, h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            final isActiveLine = lineIndex < _currentStep;
            return Expanded(
              child: Container(
                height: 3,
                color: isActiveLine ? secondaryGreen : const Color(0xFFD9E5D0),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < _currentStep;
          final isCurrent = stepIndex == _currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: w * 0.08,
            height: w * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? secondaryGreen : Colors.white,
              border: Border.all(
                color: isCurrent || isCompleted
                    ? secondaryGreen
                    : const Color(0xFFD9E5D0),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : const Color(0xFF496B35),
                ),
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
      padding: EdgeInsets.fromLTRB(w * 0.06, 18, w * 0.06, 10),
      child: Text(
        labels[_currentStep],
        style: TextStyle(
          fontSize: w * 0.046,
          color: const Color(0xFF355B27),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}