// lib/widgets/scan_detail_screen.dart

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
  static const bgColor = Color(0xFFF1EFEA);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);

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

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final scan = widget.scan;
    final imageUrl = scan['image_url'] as String?;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Scan Detail',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: w * 0.045,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scanned photo ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: h * 0.25,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(w, h),
                    )
                  : _photoPlaceholder(w, h),
            ),

            SizedBox(height: h * 0.025),

            // ── Soil scan complete ─────────────────────────
            _sectionLabel('✔ Soil Scan Complete'),
            SizedBox(height: h * 0.01),
            _infoCard(w, [
              _infoRow(
                w,
                Icons.layers,
                'Soil Type',
                scan['soil_type'] ?? '—',
                darkGreen,
              ),
              _divider(),
              _infoRow(
                w,
                Icons.eco,
                'Organic Matter',
                scan['om_level'] ?? '—',
                _chipColor(scan['om_level']),
              ),
              _divider(),
              _infoRow(
                w,
                Icons.bar_chart,
                'Confidence',
                scan['confidence'] ?? '—',
                darkGreen,
              ),
              _divider(),
              _infoRow(
                w,
                Icons.grass,
                'Crop',
                scan['crop_name'] ?? '—',
                darkGreen,
              ),
            ]),

            SizedBox(height: h * 0.025),

            // ── Recommendation ─────────────────────────────
            _sectionLabel('RECOMMENDATION'),
            SizedBox(height: h * 0.01),
            _infoCard(w, [
              _infoRow(
                w,
                Icons.check_circle_outline,
                'Compatibility',
                scan['compatibility'] ?? '—',
                _chipColor(scan['compatibility']),
              ),
            ]),

            if ((List<String>.from(scan['issues'] ?? [])).isNotEmpty) ...[
              SizedBox(height: h * 0.015),
              _sectionLabel('Issues'),
              SizedBox(height: h * 0.008),
              ...List<String>.from(
                scan['issues'],
              ).map((i) => _bulletItem(w, i, Colors.red.shade300)),
            ],

            SizedBox(height: h * 0.015),
            _sectionLabel('What to fix'),
            SizedBox(height: h * 0.008),
            ...List<String>.from(
              scan['amendments'] ?? [],
            ).map((a) => _bulletItem(w, a, darkGreen)),

            // ── Explanation ────────────────────────────────
            if (scan['explanation'] != null) ...[
              SizedBox(height: h * 0.025),
              _sectionLabel('WHAT HAPPENS IF YOU IGNORE THIS'),
              SizedBox(height: h * 0.01),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  scan['explanation'] as String,
                  style: TextStyle(
                    fontSize: w * 0.037,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // ── Chat ───────────────────────────────────────
            SizedBox(height: h * 0.03),
            const Divider(),
            _sectionLabel('ASK ABOUT THIS SCAN'),
            SizedBox(height: h * 0.01),

            Container(
              height: h * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Text(
                        'Ask anything about your soil scan.',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScroll,
                      padding: const EdgeInsets.all(10),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _chatHistory[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            constraints: BoxConstraints(maxWidth: w * 0.75),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? darkGreen.withOpacity(0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: TextStyle(fontSize: w * 0.035),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isLoadingChat)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: CircularProgressIndicator(color: darkGreen),
                ),
              ),

            SizedBox(height: h * 0.01),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask about this soil scan...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkGreen),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: darkGreen),
                  onPressed: _isLoadingChat ? null : _sendChatMessage,
                ),
              ],
            ),

            SizedBox(height: h * 0.04),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────

  Widget _photoPlaceholder(double w, double h) {
    return Container(
      width: double.infinity,
      height: h * 0.25,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.image_outlined,
        size: w * 0.15,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoCard(double w, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(
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
            Icon(icon, size: w * 0.045, color: Colors.grey.shade400),
            SizedBox(width: w * 0.025),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.035,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value[0].toUpperCase() + value.substring(1),
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w700,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Divider(height: 1),
  );

  Widget _bulletItem(double w, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: w * 0.035, color: textDark),
            ),
          ),
        ],
      ),
    );
  }
}
