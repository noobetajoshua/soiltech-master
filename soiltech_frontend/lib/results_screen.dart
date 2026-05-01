// lib/widgets/results_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/services/flask_soil_api.dart';
import 'package:soiltech/services/profile/profile_service.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> predictResult;
  final File? imageFile;
  final String cropName;
  final int drainageScore;
  // scanId is intentionally NOT a constructor param here —
  // this screen is only ever opened from ScanScreen (fresh scan).
  // History view goes through ScanDetailScreen instead.

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
  static const bgColor     = Color(0xFFF1EFEA);
  static const darkGreen   = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark    = Color(0xFF0A2418);

  Map<String, dynamic>? _recommendResult;
  Map<String, dynamic>? _explainResult;

  bool _isLoadingRecommend = false;
  bool _isLoadingExplain   = false;
  bool _isSaving           = false;
  bool _isSaved            = false;

  // Once the scan is saved this holds the Supabase scan row id.
  // While null, chat messages stay in memory only.
  String? _scanId;

  String _farmerName = 'Kuya';

  // ── Chat ────────────────────────────────────────────────────
  // All messages (pre- and post-save) live here in memory.
  // On save, any pre-save messages are bulk-inserted together
  // with the scan row. Post-save messages are inserted one-by-one.
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController  = TextEditingController();
  final ScrollController      _chatScroll      = ScrollController();
  bool _isLoadingChat = false;
  bool _chatVisible   = false;

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

  // ── Recommend ──────────────────────────────────────────────

  Future<void> _runRecommend() async {
    setState(() => _isLoadingRecommend = true);
    try {
      final result = await SoilApi.recommend(
        soilType     : widget.predictResult['soil_type'],
        omLevel      : widget.predictResult['om_level'],
        drainageScore: widget.drainageScore,
        cropName     : widget.cropName,
      );
      setState(() => _recommendResult = result);
      await _runExplain(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Recommend error: $e')));
      }
    } finally {
      setState(() => _isLoadingRecommend = false);
    }
  }

  // ── Explain ────────────────────────────────────────────────

  Future<void> _runExplain(Map<String, dynamic> recommendResult) async {
    setState(() => _isLoadingExplain = true);
    try {
      final issues = List<String>.from(recommendResult['issues'] ?? []);
      final result = await SoilApi.explain(
        soilType : widget.predictResult['soil_type'],
        omLevel  : widget.predictResult['om_level'],
        cropName : widget.cropName,
        issues   : issues,
        farmerName: _farmerName,
      );
      setState(() {
        _explainResult = result;
        _chatVisible   = true; // unlock chat immediately — in memory only
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Explain error: $e')));
      }
    } finally {
      setState(() => _isLoadingExplain = false);
    }
  }

  // ── Chat ────────────────────────────────────────────────────

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isLoadingChat = true;
    });
    _scrollToBottom();

    // If scan is already saved, persist immediately.
    // If not yet saved, message stays in memory — it will be
    // bulk-saved together with the scan when _saveScan() runs.
    if (_isSaved) await _persistChatMessage('user', text);

    try {
      final amendments = List<String>.from(
        _recommendResult?['amendments'] ?? [],
      );
      final reply = await SoilApi.chat(
        soilType  : widget.predictResult['soil_type'] ?? '',
        omLevel   : widget.predictResult['om_level']  ?? '',
        cropName  : widget.cropName,
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
      setState(() => _chatHistory.add({
        'role'   : 'assistant',
        'content': 'Sorry, something went wrong. Please try again.',
      }));
    } finally {
      setState(() => _isLoadingChat = false);
      _scrollToBottom();
    }
  }

  /// Insert a single chat message into Supabase.
  /// Only called after the scan has been saved (_scanId is set).
  Future<void> _persistChatMessage(String role, String message) async {
    if (_scanId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('chat_messages').insert({
        'scan_id': _scanId!,
        'user_id': user.id,
        'role'   : role,
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
          curve   : Curves.easeOut,
        );
      }
    });
  }

  // ── Save scan ───────────────────────────────────────────────
  // Saves the scan row AND bulk-inserts all in-memory chat messages
  // (both the ones typed before save and any typed since the screen
  // opened). After this, new messages are persisted one-by-one.

  Future<void> _saveScan() async {
    if (_recommendResult == null || _explainResult == null) return;
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Insert scan row
      final inserted = await Supabase.instance.client
          .from('scan_history')
          .insert({
            'user_id'      : user.id,
            'soil_type'    : widget.predictResult['soil_type'],
            'om_level'     : widget.predictResult['om_level'],
            'confidence'   : widget.predictResult['confidence'],
            'crop_name'    : widget.cropName,
            'compatibility': _recommendResult!['compatibility'],
            'issues'       : _recommendResult!['issues'],
            'amendments'   : _recommendResult!['amendments'],
            'explanation'  : _explainResult!['explanation'],
          })
          .select('id')
          .single();

      final scanId = inserted['id'] as String;

      // 2. Bulk-insert ALL in-memory chat messages (pre- and post-open).
      //    This preserves every question the farmer asked before saving.
      if (_chatHistory.isNotEmpty) {
        final messages = _chatHistory
            .map((m) => {
                  'scan_id': scanId,
                  'user_id': user.id,
                  'role'   : m['role']!,
                  'message': m['content']!,
                })
            .toList();
        await Supabase.instance.client.from('chat_messages').insert(messages);
      }

      setState(() {
        _scanId = scanId;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content         : Text('Scan saved successfully!'),
            backgroundColor : darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w       = MediaQuery.of(context).size.width;
    final h       = MediaQuery.of(context).size.height;
    final predict = widget.predictResult;

    return Scaffold(
      backgroundColor: bgColor,
      // The system back button / AppBar back arrow returns to Step 5
      // automatically because ScanScreen used Navigator.push (not
      // pushReplacement). No custom WillPopScope needed.
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Scan Results',
          style: TextStyle(
            color     : textDark,
            fontWeight: FontWeight.w700,
            fontSize  : w * 0.045,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical  : h * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── SCANNED PHOTO ──────────────────────────────
            if (widget.imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.imageFile!,
                  width : double.infinity,
                  height: h * 0.25,
                  fit   : BoxFit.cover,
                ),
              ),
              SizedBox(height: h * 0.01),
              Text(
                widget.imageFile!.path.split('/').last,
                style: TextStyle(
                  fontSize: w * 0.03,
                  color   : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: h * 0.02),
            ],

            // ── SOIL ANALYSIS ──────────────────────────────
            _sectionLabel('✔ Soil Scan Complete'),
            SizedBox(height: h * 0.01),
            _infoCard(w, h, [
              _infoRow('Soil Type',      predict['soil_type']  ?? '—'),
              _infoRow('Organic Matter', predict['om_level']   ?? '—'),
              _infoRow('Confidence',     predict['confidence'] ?? '—'),
              _infoRow('Crop',           widget.cropName),
              _infoRow(
                'Drainage',
                widget.drainageScore == -1
                    ? 'Poor'
                    : widget.drainageScore == 1
                        ? 'Excessive'
                        : 'Normal',
              ),
            ]),

            SizedBox(height: h * 0.025),

            // ── RECOMMENDATION ─────────────────────────────
            if (_isLoadingRecommend)
              const Center(
                child: CircularProgressIndicator(color: darkGreen),
              ),

            if (_recommendResult != null) ...[
              _sectionLabel('RECOMMENDATION'),
              SizedBox(height: h * 0.01),
              _infoCard(w, h, [
                _infoRow('Crop',          _recommendResult!['crop']          ?? '—'),
                _infoRow('Compatibility', _recommendResult!['compatibility'] ?? '—'),
              ]),

              if ((List<String>.from(_recommendResult!['issues'])).isNotEmpty) ...[
                SizedBox(height: h * 0.015),
                _sectionLabel('Issues'),
                SizedBox(height: h * 0.008),
                ...List<String>.from(_recommendResult!['issues'])
                    .map((i) => _bulletItem(w, i, Colors.red.shade300)),
              ],

              SizedBox(height: h * 0.015),
              _sectionLabel('What to fix'),
              SizedBox(height: h * 0.008),
              ...List<String>.from(_recommendResult!['amendments'])
                  .map((a) => _bulletItem(w, a, darkGreen)),
            ],

            // ── EXPLANATION ────────────────────────────────
            if (_isLoadingExplain) ...[
              SizedBox(height: h * 0.02),
              const Center(
                child: CircularProgressIndicator(color: darkGreen),
              ),
            ],

            if (_explainResult != null) ...[
              SizedBox(height: h * 0.025),
              _sectionLabel('WHAT HAPPENS IF YOU IGNORE THIS'),
              SizedBox(height: h * 0.01),
              Container(
                width  : double.infinity,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color       : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border      : Border.all(color: borderColor),
                ),
                child: Text(
                  _explainResult!['explanation'] ?? '',
                  style: TextStyle(
                    fontSize: w * 0.037,
                    color   : textDark,
                    height  : 1.5,
                  ),
                ),
              ),
            ],

            // ── CHAT — unlocked after explain loads ────────
            if (_chatVisible) ...[
              SizedBox(height: h * 0.03),
              const Divider(),

              // Hint shown before scan is saved
              if (!_isSaved)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chat is saved when you tap "Save Scan".',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color   : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _sectionLabel('ASK ABOUT THIS SCAN'),
              SizedBox(height: h * 0.01),

              Container(
                height    : h * 0.35,
                decoration: BoxDecoration(
                  color       : Colors.white,
                  border      : Border.all(color: borderColor),
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
                        padding   : const EdgeInsets.all(10),
                        itemCount : _chatHistory.length,
                        itemBuilder: (context, index) {
                          final msg    = _chatHistory[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin     : const EdgeInsets.symmetric(vertical: 4),
                              padding    : const EdgeInsets.all(10),
                              constraints: BoxConstraints(maxWidth: w * 0.75),
                              decoration : BoxDecoration(
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
                  child  : Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  ),
                ),

              SizedBox(height: h * 0.01),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller     : _chatController,
                      maxLines       : null,
                      minLines       : 1,
                      keyboardType   : TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration     : InputDecoration(
                        hintText : 'Ask about this soil scan...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border   : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(color: darkGreen),
                        ),
                        isDense       : true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical  : 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon     : const Icon(Icons.send, color: darkGreen),
                    onPressed: _isLoadingChat ? null : _sendChatMessage,
                  ),
                ],
              ),

              SizedBox(height: h * 0.025),
            ],

            // ── SAVE SCAN — visible before save ────────────
            if (_explainResult != null && !_isSaved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding  : EdgeInsets.symmetric(vertical: h * 0.02),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width : 20,
                          height: 20,
                          child : CircularProgressIndicator(
                            color      : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Scan →',
                          style: TextStyle(
                            color     : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

            // ── SAVED CONFIRMATION — visible after save ─────
            // No "View Saved Scan" navigation button: the farmer
            // uses the back arrow to return to Step 5, or navigates
            // to History through the bottom nav. This prevents a
            // second screen being pushed and avoids state confusion.
            if (_isSaved) ...[
              Container(
                width  : double.infinity,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color       : darkGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border      : Border.all(color: darkGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: darkGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Scan saved! Find it in History anytime.',
                        style: TextStyle(
                          fontSize  : w * 0.035,
                          color     : darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: h * 0.04),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize     : 13,
        fontWeight   : FontWeight.w700,
        color        : Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoCard(double w, double h, List<Widget> children) {
    return Container(
      width  : double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color     : textDark,
              fontSize  : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(double w, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width : 7,
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