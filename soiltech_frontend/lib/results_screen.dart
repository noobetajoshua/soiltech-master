// lib/widgets/results_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soiltech/services/flask_soil_api.dart';
import 'package:soiltech/services/profile/profile_service.dart';
import 'scan_saved_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> predictResult;
  final File imageFile;
  final String cropName;
  final int drainageScore;
  final String? scanId;

  const ResultsScreen({
    super.key,
    required this.predictResult,
    required this.imageFile,
    required this.cropName,
    required this.drainageScore,
    this.scanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // ── Constants ──────────────────────────────────────────────
  static const bgColor = Color(0xFFF1EFEA);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);

  // ── Scan flow state ────────────────────────────────────────
  Map<String, dynamic>? _recommendResult;
  Map<String, dynamic>? _explainResult;

  bool _isLoadingRecommend = false;
  bool _isLoadingExplain = false;
  bool _isSaved = false;

  String? _scanId;
  String _farmerName = 'Kuya';

  // ── Chat state ─────────────────────────────────────────────
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isLoadingChat = false;
  bool _chatVisible = false;

  // ── Lifecycle ──────────────────────────────────────────────

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
    if (widget.scanId != null) {
      _scanId = widget.scanId;
      _chatVisible = true;
      _loadChatFromSupabase();
    } else {
      _runRecommend();
    }
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

  // ── Load chat from Supabase ────────────────────────────────

  Future<void> _loadChatFromSupabase() async {
    if (_scanId == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('chat_messages')
          .select('role, message')
          .eq('scan_id', _scanId!)
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
      await _saveChatMessage('assistant', reply);
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

  // ── Recommend ──────────────────────────────────────────────

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

  // ── Explain ────────────────────────────────────────────────

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
      setState(() => _explainResult = result);
      await _saveToSupabase(recommendResult, result);
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

  // ── Save to Supabase + upload image ────────────────────────

  Future<void> _saveToSupabase(
    Map<String, dynamic> recommend,
    Map<String, dynamic> explain,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // ── Upload image to scan-images bucket ────────────────
      String? imageUrl;
      try {
        final fileBytes = await widget.imageFile.readAsBytes();
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await Supabase.instance.client.storage
            .from('scan-images')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        imageUrl = Supabase.instance.client.storage
            .from('scan-images')
            .getPublicUrl(fileName);
      } catch (_) {
        // Upload failure is non-blocking — scan still saves without photo
        imageUrl = null;
      }

      // ── Insert scan_history row ───────────────────────────
      final inserted = await Supabase.instance.client
          .from('scan_history')
          .insert({
            'user_id': user.id,
            'soil_type': widget.predictResult['soil_type'],
            'om_level': widget.predictResult['om_level'],
            'confidence': widget.predictResult['confidence'],
            'crop_name': widget.cropName,
            'compatibility': recommend['compatibility'],
            'issues': recommend['issues'],
            'amendments': recommend['amendments'],
            'explanation': explain['explanation'],
            'image_url': imageUrl,
          })
          .select('id')
          .single();

      setState(() {
        _scanId = inserted['id'] as String;
        _isSaved = true;
        _chatVisible = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    }
  }

  void _goToScanSaved() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScanSavedScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final predict = widget.predictResult;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Scan Results',
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
              child: Image.file(
                widget.imageFile,
                width: double.infinity,
                height: h * 0.25,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(height: h * 0.025),

            // ── Soil analysis ──────────────────────────────
            _sectionLabel('✔ Soil Scan Complete'),
            SizedBox(height: h * 0.01),
            _infoCard(w, h, [
              _infoRow('Soil Type', predict['soil_type'] ?? '—'),
              _infoRow('Organic Matter', predict['om_level'] ?? '—'),
              _infoRow('Confidence', predict['confidence'] ?? '—'),
              _infoRow('Crop', widget.cropName),
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

            // ── Recommendation ─────────────────────────────
            if (_isLoadingRecommend)
              const Center(child: CircularProgressIndicator(color: darkGreen)),

            if (_recommendResult != null) ...[
              _sectionLabel('RECOMMENDATION'),
              SizedBox(height: h * 0.01),
              _infoCard(w, h, [
                _infoRow('Crop', _recommendResult!['crop'] ?? '—'),
                _infoRow(
                  'Compatibility',
                  _recommendResult!['compatibility'] ?? '—',
                ),
              ]),

              if ((List<String>.from(
                _recommendResult!['issues'],
              )).isNotEmpty) ...[
                SizedBox(height: h * 0.015),
                _sectionLabel('Issues'),
                SizedBox(height: h * 0.008),
                ...List<String>.from(
                  _recommendResult!['issues'],
                ).map((i) => _bulletItem(w, i, Colors.red.shade300)),
              ],

              SizedBox(height: h * 0.015),
              _sectionLabel('What to fix'),
              SizedBox(height: h * 0.008),
              ...List<String>.from(
                _recommendResult!['amendments'],
              ).map((a) => _bulletItem(w, a, darkGreen)),
            ],

            // ── Explanation ────────────────────────────────
            if (_isLoadingExplain) ...[
              SizedBox(height: h * 0.02),
              const Center(child: CircularProgressIndicator(color: darkGreen)),
            ],

            if (_explainResult != null) ...[
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
                  _explainResult!['explanation'] ?? '',
                  style: TextStyle(
                    fontSize: w * 0.037,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // ── Chat ───────────────────────────────────────
            if (_chatVisible) ...[
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

              // ── Chat input ─────────────────────────────────
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

              SizedBox(height: h * 0.025),

              // ── Save Scan button ───────────────────────────
              if (_isSaved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToScanSaved,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: h * 0.02),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Scan →',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoCard(double w, double h, List<Widget> children) {
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: textDark,
              fontSize: 13,
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
