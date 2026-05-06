// lib/widgets/history_scan_details_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/services/flask_soil_api.dart';
import 'package:soiltech/services/profile/profile_service.dart';

class ScanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> scan;

  const ScanDetailScreen({super.key, required this.scan});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  // ── Constants ──────────────────────────────────────────────
  static const bgColor = Color(0xFFFBFAF5);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);
  static const deepGreen = Color(0xFF0A4A1D);
  static const navyText = Color(0xFF17324A);
  static const redColor = Color(0xFFFF4242);
  static const goldColor = Color(0xFFC79A23);

  static const String _chatAssistAsset = 'assets/logo/chatassist.png';

  // ── Chat state ─────────────────────────────────────────────
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isLoadingChat = false;
  String _farmerName = 'Kuya';

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
    await _loadChatFromSupabase();
  }

  // ── Load farmer name ───────────────────────────────────────
  Future<void> _loadFarmerName() async {
    try {
      final profile = await ProfileService().getFarmerProfile();
      if (mounted) {
        setState(() => _farmerName = profile?['username'] ?? 'Kuya');
      }
    } catch (_) {}
  }

  // ── Load chat ──────────────────────────────────────────────
  Future<void> _loadChatFromSupabase() async {
    final scanId = widget.scan['id'] as String?;
    if (scanId == null) return;

    try {
      final rows = await Supabase.instance.client
          .from('chat_messages')
          .select('role, message')
          .eq('scan_id', scanId)
          .order('created_at');

      setState(() {
        _chatHistory.clear();
        for (final row in rows) {
          _chatHistory.add({
            'role': row['role'] as String,
            'content': row['message'] as String,
          });
        }
      });
      _scrollToBottom();
    } catch (_) {}
  }

  // ── Save chat message ──────────────────────────────────────
  Future<void> _saveChatMessage(String role, String message) async {
    final scanId = widget.scan['id'] as String?;
    if (scanId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('chat_messages').insert({
        'scan_id': scanId,
        'user_id': user.id,
        'role': role,
        'message': message,
      });
    } catch (_) {}
  }

  // ── Send chat ──────────────────────────────────────────────
  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isLoadingChat = true;
    });
    _scrollToBottom();
    await _saveChatMessage('user', text);

    try {
      final amendments = List<String>.from(widget.scan['amendments'] ?? []);

      final reply = await SoilApi.chat(
        soilType: widget.scan['soil_type'] ?? '',
        omLevel: widget.scan['om_level'] ?? '',
        cropName: widget.scan['crop_name'] ?? '',
        amendments: amendments,
        farmerName: _farmerName,
        conversationHistory: _chatHistory
            .sublist(0, _chatHistory.length - 1)
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
        userMessage: text,
      );

      setState(() => _chatHistory.add({'role': 'assistant', 'content': reply}));
      await _saveChatMessage('assistant', reply);
    } catch (e) {
      // Joshua's timeout-aware error handling
      final isTimeout =
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException');
      setState(
        () => _chatHistory.add({
          'role': 'assistant',
          'content': isTimeout
              ? 'Connection timed out. The server may be starting up — please wait a moment and try again.'
              : 'Sorry, something went wrong. Please try again.',
        }),
      );
    } finally {
      setState(() => _isLoadingChat = false);
      _scrollToBottom();
    }
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

  // ── Helpers ────────────────────────────────────────────────
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
    if (text.toLowerCase() == 'not_suitable') return 'Not suitable';
    return text[0].toUpperCase() + text.substring(1);
  }

  void _openChatAssistPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ScanChatAssistPage(parent: this)),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final scan = widget.scan;
    final imageUrl = scan['image_url'] as String?;
    final issues = List<String>.from(scan['issues'] ?? []);
    final amendments = List<String>.from(scan['amendments'] ?? []);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFCF5),
                    Color(0xFFFCFBF3),
                    Color(0xFFF7FAEE),
                  ],
                ),
              ),
            ),
          ),

          // Decorative eco icon
          Positioned(
            top: h * 0.08,
            right: -w * 0.10,
            child: Icon(
              Icons.eco_rounded,
              color: darkGreen.withOpacity(0.08),
              size: w * 0.42,
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar row
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
                        width: w * 0.072,
                        height: w * 0.072,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF4DD),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: deepGreen,
                            size: w * 0.04,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.025),
                      Text(
                        'Scan Detail',
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
                    padding: EdgeInsets.fromLTRB(
                      w * 0.045,
                      h * 0.005,
                      w * 0.045,
                      h * 0.11,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topScanCard(w, h, scan, imageUrl),

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
                          value: _cleanValue(scan['compatibility']),
                          color: _chipColor(scan['compatibility']),
                        ),

                        if (issues.isNotEmpty) ...[
                          SizedBox(height: h * 0.022),
                          _issuesCard(w, issues),
                        ],

                        SizedBox(height: h * 0.022),
                        _fixCard(w, amendments),

                        if (scan['explanation'] != null) ...[
                          SizedBox(height: h * 0.022),
                          _ignoreCard(w, _cleanValue(scan['explanation'])),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating chat button
          Positioned(
            right: w * 0.035,
            bottom: h * 0.035,
            child: _chatFloatingButton(w),
          ),
        ],
      ),
    );
  }

  // ── UI widgets ─────────────────────────────────────────────

  Widget _topScanCard(
    double w,
    double h,
    Map<String, dynamic> scan,
    String? imageUrl,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.028),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
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
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: w * 0.42,
                    height: h * 0.19,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(w, h),
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
                SizedBox(height: h * 0.015),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.layers_rounded,
                  'Soil Type',
                  _cleanValue(scan['soil_type']),
                  darkGreen,
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.eco_rounded,
                  'Organic Matter',
                  _cleanValue(scan['om_level']),
                  _chipColor(scan['om_level']),
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.bar_chart_rounded,
                  'Confidence',
                  _cleanValue(scan['confidence']),
                  darkGreen,
                ),
                _thinDivider(),
                _scanInfoRow(
                  w,
                  Icons.grass_rounded,
                  'Crop',
                  _cleanValue(scan['crop_name']),
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
      padding: EdgeInsets.symmetric(vertical: w * 0.014),
      child: Row(
        children: [
          Container(
            width: w * 0.045,
            height: w * 0.045,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6E7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: darkGreen, size: w * 0.031),
          ),
          SizedBox(width: w * 0.015),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: navyText,
                fontSize: w * 0.028,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.022,
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
                fontSize: w * 0.026,
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
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: w * 0.038),
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
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.022),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
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
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6E7),
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
                  .map((i) => _bulletText(w, text: i, color: redColor))
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
              color: const Color(0xFFEAF4DD),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFB7D09A)),
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
            padding: EdgeInsets.all(w * 0.008),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB7D09A), width: 2),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
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
      height: h * 0.19,
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

  Widget _bulletText(double w, {required String text, required Color color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.014),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: w * 0.01),
            width: w * 0.011,
            height: w * 0.011,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

// ─────────────────────────────────────────────────────────────
// Separate chatbot page for Ask About This Scan
// ─────────────────────────────────────────────────────────────

class _ScanChatAssistPage extends StatefulWidget {
  final _ScanDetailScreenState parent;

  const _ScanChatAssistPage({required this.parent});

  @override
  State<_ScanChatAssistPage> createState() => _ScanChatAssistPageState();
}

class _ScanChatAssistPageState extends State<_ScanChatAssistPage> {
  static const Color bgColor = Color(0xFFFBFAF5);
  static const Color darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const Color deepGreen = Color(0xFF0A4A1D);
  static const Color borderColor = Color(0xFF7D9C74);
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

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
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
                // Header
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
                        width: w * 0.072,
                        height: w * 0.072,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF4DD),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: deepGreen,
                            size: w * 0.04,
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
                            color: const Color(0xFFB7D09A),
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

                // Intro banner
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
                            color: const Color(0xFFEAF4DD),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFB7D09A)),
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
                            'Ask anything about your soil scan, issues, crop compatibility, or what to fix.',
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

                // Chat messages
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
                                        ? darkGreen.withOpacity(0.16)
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
                                          ? darkGreen.withOpacity(0.22)
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

                // Input row
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
                              borderSide: const BorderSide(color: borderColor),
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
