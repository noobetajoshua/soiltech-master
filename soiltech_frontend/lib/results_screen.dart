import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/services/flask_soil_api.dart';
import 'package:soiltech/services/profile/profile_service.dart';
import 'scan_saved_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> predictResult;
  final File? imageFile;
  final String cropName;
  final int drainageScore;

  const ResultsScreen({
    super.key,
    required this.predictResult,
    this.imageFile,
    required this.cropName,
    required this.drainageScore,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  static const bgColor = Color(0xFFF5F8D6);
  static const darkGreen = Color(0xFF2F5E1A);
  static const primaryGreen = Color(0xFFC1D95C);
  static const secondaryGreen = Color(0xFF80B155);
  static const borderColor = Color(0xFF80B155);
  static const textDark = Color(0xFF0A2418);
  static const cream = Color(0xFFF8F3D9);

  static const deepGreen = Color(0xFF2F5E1A);
  static const navyText = Color(0xFF17324A);
  static const redColor = Color(0xFFFF4242);
  static const goldColor = Color(0xFFC79A23);

  static const String _chatAssistAsset = 'assets/logo/chatassist.png';

  Map<String, dynamic>? _recommendResult;
  Map<String, dynamic>? _explainResult;

  bool _isLoadingRecommend = false;
  bool _isLoadingExplain = false;
  bool _isSaving = false;
  bool _isSaved = false;

  String? _scanId;
  String _farmerName = 'Kuya';

  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isLoadingChat = false;
  bool _chatVisible = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadFarmerName();
    _runRecommend();
  }

  Future<void> _loadFarmerName() async {
    try {
      final profile = await ProfileService().getFarmerProfile();
      if (mounted) setState(() => _farmerName = profile?['username'] ?? 'Kuya');
    } catch (_) {}
  }

  Future<void> _runRecommend() async {
    setState(() => _isLoadingRecommend = true);

    try {
      final result = await SoilApi.recommend(
        soilType: widget.predictResult['soil_type'],
        omLevel: widget.predictResult['om_level'],
        drainageScore: widget.drainageScore,
        cropName: widget.cropName,
      );

      setState(() => _recommendResult = result);
      await _runExplain(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recommend error: $e')));
      }
    } finally {
      setState(() => _isLoadingRecommend = false);
    }
  }

  Future<void> _runExplain(Map<String, dynamic> recommendResult) async {
    setState(() => _isLoadingExplain = true);

    try {
      final issues = List<String>.from(recommendResult['issues'] ?? []);
      final result = await SoilApi.explain(
        soilType: widget.predictResult['soil_type'],
        omLevel: widget.predictResult['om_level'],
        cropName: widget.cropName,
        issues: issues,
        farmerName: _farmerName,
      );

      setState(() {
        _explainResult = result;
        _chatVisible = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Explain error: $e')));
      }
    } finally {
      setState(() => _isLoadingExplain = false);
    }
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isLoadingChat = true;
    });

    _scrollToBottom();

    if (_isSaved) await _persistChatMessage('user', text);

    try {
      final amendments = List<String>.from(
        _recommendResult?['amendments'] ?? [],
      );

      final reply = await SoilApi.chat(
        soilType: widget.predictResult['soil_type'] ?? '',
        omLevel: widget.predictResult['om_level'] ?? '',
        cropName: widget.cropName,
        amendments: amendments,
        farmerName: _farmerName,
        conversationHistory: _chatHistory
            .sublist(0, _chatHistory.length - 1)
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
        userMessage: text,
      );

      setState(() => _chatHistory.add({'role': 'assistant', 'content': reply}));

      if (_isSaved) await _persistChatMessage('assistant', reply);
    } catch (_) {
      setState(
        () => _chatHistory.add({
          'role': 'assistant',
          'content': 'Sorry, something went wrong. Please try again.',
        }),
      );
    } finally {
      setState(() => _isLoadingChat = false);
      _scrollToBottom();
    }
  }

  Future<void> _persistChatMessage(String role, String message) async {
    if (_scanId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('chat_messages').insert({
        'scan_id': _scanId!,
        'user_id': user.id,
        'role': role,
        'message': message,
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final fileName =
          'soil_scans/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage.from('scan-images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      return Supabase.instance.client.storage
          .from('scan-images')
          .getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveScan() async {
    if (_recommendResult == null || _explainResult == null) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (widget.imageFile != null) {
        imageUrl = await _uploadImage(widget.imageFile!, user.id);
      }

      final inserted = await Supabase.instance.client
          .from('scan_history')
          .insert({
            'user_id': user.id,
            'soil_type': widget.predictResult['soil_type'],
            'om_level': widget.predictResult['om_level'],
            'confidence': widget.predictResult['confidence'],
            'crop_name': widget.cropName,
            'compatibility': _recommendResult!['compatibility'],
            'issues': _recommendResult!['issues'],
            'amendments': _recommendResult!['amendments'],
            'explanation': _explainResult!['explanation'],
            'image_url': imageUrl,
          })
          .select('id')
          .single();

      final scanId = inserted['id'] as String;

      if (_chatHistory.isNotEmpty) {
        final messages = _chatHistory
            .map(
              (m) => {
                'scan_id': scanId,
                'user_id': user.id,
                'role': m['role']!,
                'message': m['content']!,
              },
            )
            .toList();

        await Supabase.instance.client.from('chat_messages').insert(messages);
      }

      setState(() {
        _scanId = scanId;
        _isSaved = true;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanSavedScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Color _chipColor(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return Colors.green.shade600;
      case 'moderate':
        return Colors.orange.shade600;
      case 'low':
        return Colors.red.shade400;
      case 'suitable':
        return Colors.green.shade600;
      case 'fair':
        return Colors.orange.shade600;
      case 'not_suitable':
        return Colors.red.shade400;
      default:
        return darkGreen;
    }
  }

  String _cleanValue(dynamic value) {
    if (value == null) return '—';

    final text = value.toString();
    if (text.isEmpty) return '—';

    if (text.toLowerCase() == 'not_suitable') {
      return 'Not suitable';
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  String _drainageText() {
    if (widget.drainageScore == -1) return 'Poor';
    if (widget.drainageScore == 1) return 'Excessive';
    return 'Normal';
  }

  void _openChatAssistPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultsChatAssistPage(parent: this),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final predict = widget.predictResult;

    final issues = List<String>.from(_recommendResult?['issues'] ?? []);
    final amendments = List<String>.from(_recommendResult?['amendments'] ?? []);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5F8D6),
                    Color(0xFFFBFCED),
                    Color(0xFFFFFEF7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.08,
            right: -w * 0.10,
            child: Icon(
              Icons.eco_rounded,
              color: darkGreen.withOpacity(0.08),
              size: w * 0.42,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.045,
                    h * 0.018,
                    w * 0.045,
                    h * 0.012,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: w * 0.075,
                        height: w * 0.075,
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: deepGreen,
                            size: w * 0.045,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.025),
                      Text(
                        'Scan Results',
                        style: TextStyle(
                          color: deepGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: w * 0.052,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      w * 0.045,
                      h * 0.005,
                      w * 0.045,
                      h * 0.035,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topScanCard(w, h, predict),
                        if (_isLoadingRecommend) ...[
                          SizedBox(height: h * 0.03),
                          const Center(
                            child: CircularProgressIndicator(
                              color: darkGreen,
                            ),
                          ),
                        ],
                        if (_recommendResult != null) ...[
                          SizedBox(height: h * 0.024),
                          _sectionTitle(
                            w,
                            icon: Icons.eco_rounded,
                            title: 'Recommendation',
                            color: deepGreen,
                          ),
                          SizedBox(height: h * 0.008),
                          _compatibilityCard(
                            w: w,
                            label: 'Compatibility',
                            value: _cleanValue(
                              _recommendResult!['compatibility'],
                            ),
                            color: _chipColor(
                              _recommendResult!['compatibility']?.toString(),
                            ),
                          ),
                          if (issues.isNotEmpty) ...[
                            SizedBox(height: h * 0.022),
                            _issuesCard(w, issues),
                          ],
                          SizedBox(height: h * 0.022),
                          _fixCard(w, amendments),
                        ],
                        if (_isLoadingExplain) ...[
                          SizedBox(height: h * 0.025),
                          const Center(
                            child: CircularProgressIndicator(
                              color: darkGreen,
                            ),
                          ),
                        ],
                        if (_explainResult != null) ...[
                          SizedBox(height: h * 0.022),
                          _ignoreCard(
                            w,
                            _cleanValue(_explainResult!['explanation']),
                          ),
                          SizedBox(height: h * 0.026),
                          _saveScanCard(w, h),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_chatVisible)
            Positioned(
              right: w * 0.035,
              bottom: h * 0.035,
              child: _chatFloatingButton(w),
            ),
        ],
      ),
    );
  }

  Widget _topScanCard(
    double w,
    double h,
    Map<String, dynamic> predict,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.028),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.imageFile != null
                ? Image.file(
                    widget.imageFile!,
                    width: w * 0.42,
                    height: h * 0.21,
                    fit: BoxFit.cover,
                  )
                : _photoPlaceholder(w, h),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: w * 0.055,
                      height: w * 0.055,
                      decoration: const BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: w * 0.042,
                      ),
                    ),
                    SizedBox(width: w * 0.018),
                    Expanded(
                      child: Text(
                        'Soil Scan Complete',
                        style: TextStyle(
                          color: deepGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: w * 0.031,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.012),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.layers_rounded,
                  'Soil Type',
                  _cleanValue(predict['soil_type']),
                  darkGreen,
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.eco_rounded,
                  'Organic Matter',
                  _cleanValue(predict['om_level']),
                  _chipColor(predict['om_level']?.toString()),
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.bar_chart_rounded,
                  'Confidence',
                  _cleanValue(predict['confidence']),
                  darkGreen,
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.grass_rounded,
                  'Crop',
                  widget.cropName,
                  darkGreen,
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.water_drop_outlined,
                  'Drainage',
                  _drainageText(),
                  darkGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanInfoRow(
    double w,
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.011),
      child: Row(
        children: [
          Container(
            width: w * 0.045,
            height: w * 0.045,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: darkGreen,
              size: w * 0.031,
            ),
          ),
          SizedBox(width: w * 0.015),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: navyText,
                fontSize: w * 0.027,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.019,
              vertical: w * 0.007,
            ),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: w * 0.025,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    double w, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: w * 0.056,
          height: w * 0.056,
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: w * 0.038,
          ),
        ),
        SizedBox(width: w * 0.014),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: w * 0.034,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _compatibilityCard({
    required double w,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.035,
        vertical: w * 0.022,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAD8)),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.052,
            height: w * 0.052,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: darkGreen,
              size: w * 0.034,
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: navyText,
                fontSize: w * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.027,
              vertical: w * 0.009,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: w * 0.03,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _issuesCard(double w, List<String> issues) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.024),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA).withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD2D2)),
        boxShadow: [
          BoxShadow(
            color: redColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: w * 0.044,
                height: w * 0.044,
                decoration: const BoxDecoration(
                  color: redColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: w * 0.032,
                ),
              ),
              SizedBox(width: w * 0.014),
              Text(
                'Issues',
                style: TextStyle(
                  color: deepGreen,
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB8B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: issues
                  .map(
                    (issue) => _bulletText(
                      w,
                      text: issue,
                      color: redColor,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fixCard(double w, List<String> fixes) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.024),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EBD5)),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: w * 0.044,
                height: w * 0.044,
                decoration: const BoxDecoration(
                  color: darkGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: Colors.white,
                  size: w * 0.03,
                ),
              ),
              SizedBox(width: w * 0.014),
              Text(
                'What to fix',
                style: TextStyle(
                  color: deepGreen,
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDEAD0)),
            ),
            child: Column(
              children: [
                for (final fix in fixes)
                  Padding(
                    padding: EdgeInsets.only(bottom: w * 0.012),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: w * 0.005),
                          width: w * 0.023,
                          height: w * 0.023,
                          decoration: const BoxDecoration(
                            color: darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: w * 0.016,
                          ),
                        ),
                        SizedBox(width: w * 0.014),
                        Expanded(
                          child: Text(
                            fix,
                            style: TextStyle(
                              color: navyText,
                              fontSize: w * 0.027,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ignoreCard(double w, String explanation) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.024),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4).withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0CF79)),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: w * 0.044,
                height: w * 0.044,
                decoration: const BoxDecoration(
                  color: goldColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: w * 0.03,
                ),
              ),
              SizedBox(width: w * 0.014),
              Expanded(
                child: Text(
                  'What happens if you ignore this',
                  style: TextStyle(
                    color: deepGreen,
                    fontSize: w * 0.033,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8C86D)),
            ),
            child: Text(
              explanation,
              style: TextStyle(
                color: navyText,
                fontSize: w * 0.029,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveScanCard(double w, double h) {
    if (_isSaved) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.026),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EBD5)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: h * 0.062,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: darkGreen,
                ),
                label: const Text(
                  'Back',
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: darkGreen,
                    width: 1.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: h * 0.062,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: _isSaving ? 0 : 8,
                  shadowColor: darkGreen.withOpacity(0.22),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: _isSaving
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFC1D95C),
                              Color(0xFF80B155),
                              Color(0xFF2F5E1A),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Save Scan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: w * 0.018),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatFloatingButton(double w) {
    return GestureDetector(
      onTap: _openChatAssistPage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.28,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * 0.012,
            ),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.35),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: secondaryGreen.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              'Ask about\nthis scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkGreen,
                fontWeight: FontWeight.w900,
                fontSize: w * 0.024,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: w * 0.01),
          Container(
            width: w * 0.13,
            height: w * 0.13,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: secondaryGreen.withOpacity(0.75),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            padding: EdgeInsets.all(w * 0.008),
            child: Image.asset(
              _chatAssistAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.smart_toy_rounded,
                color: darkGreen,
                size: w * 0.075,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(double w, double h) {
    return Container(
      width: w * 0.42,
      height: h * 0.21,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.image_outlined,
        size: w * 0.13,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _thinDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFDDE6D4).withOpacity(0.75),
    );
  }

  Widget _bulletText(
    double w, {
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.014),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: w * 0.01),
            width: w * 0.011,
            height: w * 0.011,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: w * 0.018),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: navyText,
                fontSize: w * 0.03,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsChatAssistPage extends StatefulWidget {
  final _ResultsScreenState parent;

  const _ResultsChatAssistPage({required this.parent});

  @override
  State<_ResultsChatAssistPage> createState() => _ResultsChatAssistPageState();
}

class _ResultsChatAssistPageState extends State<_ResultsChatAssistPage> {
  static const Color bgColor = Color(0xFFF5F8D6);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color deepGreen = Color(0xFF2F5E1A);
  static const Color borderColor = Color(0xFF80B155);
  static const Color navyText = Color(0xFF17324A);

  static const String _chatAssistAsset = 'assets/logo/chatassist.png';

  Future<void> _send() async {
    await widget.parent._sendChatMessage();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final chatHistory = widget.parent._chatHistory;
    final chatController = widget.parent._chatController;
    final chatScroll = widget.parent._chatScroll;
    final isLoadingChat = widget.parent._isLoadingChat;
    final isSaved = widget.parent._isSaved;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5F8D6),
                    Color(0xFFFBFCED),
                    Color(0xFFFFFEF7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.08,
            right: -w * 0.12,
            child: Icon(
              Icons.eco_rounded,
              color: darkGreen.withOpacity(0.08),
              size: w * 0.50,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.045,
                    h * 0.018,
                    w * 0.045,
                    h * 0.012,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: w * 0.075,
                        height: w * 0.075,
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: deepGreen,
                            size: w * 0.045,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.025),
                      Expanded(
                        child: Text(
                          'Ask About This Scan',
                          style: TextStyle(
                            color: deepGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.044,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        width: w * 0.075,
                        height: w * 0.075,
                        padding: EdgeInsets.all(w * 0.006),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: secondaryGreen.withOpacity(0.65),
                            width: 1.4,
                          ),
                        ),
                        child: Image.asset(
                          _chatAssistAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.smart_toy_rounded,
                            color: darkGreen,
                            size: w * 0.045,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.035),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDEAD0)),
                      boxShadow: [
                        BoxShadow(
                          color: deepGreen.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: w * 0.11,
                          height: w * 0.11,
                          padding: EdgeInsets.all(w * 0.008),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.28),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: secondaryGreen.withOpacity(0.55),
                            ),
                          ),
                          child: Image.asset(
                            _chatAssistAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.smart_toy_rounded,
                              color: darkGreen,
                              size: w * 0.06,
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.025),
                        Expanded(
                          child: Text(
                            isSaved
                                ? 'Ask anything about your saved soil scan.'
                                : 'Ask anything about this scan. Chat will be saved when you tap Save Scan.',
                            style: TextStyle(
                              color: navyText,
                              fontSize: w * 0.032,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * 0.014),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: w * 0.045),
                    padding: EdgeInsets.all(w * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor.withOpacity(0.75)),
                    ),
                    child: chatHistory.isEmpty
                        ? Center(
                            child: Text(
                              'Start a conversation about this scan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: w * 0.034,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: chatScroll,
                            itemCount: chatHistory.length,
                            itemBuilder: (context, index) {
                              final msg = chatHistory[index];
                              final isUser = msg['role'] == 'user';

                              return Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    vertical: h * 0.006,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.032,
                                    vertical: w * 0.025,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: w * 0.72,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? secondaryGreen.withOpacity(0.22)
                                        : const Color(0xFFF3F7ED),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isUser ? 16 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isUser ? 4 : 16,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: isUser
                                          ? secondaryGreen.withOpacity(0.35)
                                          : const Color(0xFFDDEAD0),
                                    ),
                                  ),
                                  child: Text(
                                    msg['content'] ?? '',
                                    style: TextStyle(
                                      color: navyText,
                                      fontSize: w * 0.034,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                if (isLoadingChat)
                  Padding(
                    padding: EdgeInsets.only(top: h * 0.01),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: darkGreen,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.045,
                    h * 0.012,
                    w * 0.045,
                    h * 0.018,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController,
                          maxLines: null,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Ask about this soil scan...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: w * 0.034,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: borderColor.withOpacity(0.65),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: darkGreen,
                                width: 1.5,
                              ),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: w * 0.035,
                              vertical: h * 0.014,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      Container(
                        width: w * 0.12,
                        height: w * 0.12,
                        decoration: const BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: w * 0.052,
                          ),
                          onPressed: isLoadingChat ? null : _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}