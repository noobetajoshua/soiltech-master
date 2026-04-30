import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/flask_soil_api.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> predictResult;
  final File imageFile;

  // When opened from history, scanId is provided so chat loads from Supabase
  final String? scanId;

  const ResultsScreen({
    super.key,
    required this.predictResult,
    required this.imageFile,
    this.scanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // ─── Scan flow state ───────────────────────────────────────
  int _drainageScore = 0;
  bool _drainageSubmitted = false;

  final TextEditingController _cropController = TextEditingController();
  bool _cropSubmitted = false;

  Map<String, dynamic>? _recommendResult;
  Map<String, dynamic>? _explainResult;

  bool _isLoadingRecommend = false;
  bool _isLoadingExplain = false;
  bool _isSaved = false;

  // Supabase scan_id assigned after saving
  String? _scanId;

  // ─── Chat state ────────────────────────────────────────────
  // Each entry: {'role': 'user'|'assistant', 'content': '...'}
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isLoadingChat = false;
  bool _chatVisible = false;

  @override
  void initState() {
    super.initState();
    // If opened from history, load existing chat and show it immediately
    if (widget.scanId != null) {
      _scanId = widget.scanId;
      _chatVisible = true;
      _drainageSubmitted = true;
      _cropSubmitted = true;
      _loadChatFromSupabase();
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 11 — Load previous messages from Supabase
  // ─────────────────────────────────────────────────────────────
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
    } catch (e) {
      // Non-blocking — chat still works even if load fails
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 10 — Save a single message to Supabase
  // ─────────────────────────────────────────────────────────────
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
    } catch (_) {
      // Save failure is silent — message already shown in UI
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT SEND
  // ─────────────────────────────────────────────────────────────
  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final userEntry = {'role': 'user', 'content': text};
    setState(() {
      _chatHistory.add(userEntry);
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
        cropName: _cropController.text.trim().isNotEmpty
            ? _cropController.text.trim()
            : (widget.predictResult['crop_name'] ?? ''),
        amendments: amendments,
        // Pass only role/content pairs — strip any extra keys
        conversationHistory: _chatHistory
            .sublist(
              0,
              _chatHistory.length - 1,
            ) // exclude the message just added
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
        userMessage: text,
      );

      final assistantEntry = {'role': 'assistant', 'content': reply};
      setState(() => _chatHistory.add(assistantEntry));
      await _saveChatMessage('assistant', reply);
    } catch (e) {
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

  // ─────────────────────────────────────────────────────────────
  // SCAN FLOW
  // ─────────────────────────────────────────────────────────────
  Future<void> _runRecommend() async {
    if (_cropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a crop name')));
      return;
    }

    setState(() {
      _isLoadingRecommend = true;
      _cropSubmitted = true;
    });

    try {
      final result = await SoilApi.recommend(
        soilType: widget.predictResult['soil_type'],
        omLevel: widget.predictResult['om_level'],
        drainageScore: _drainageScore,
        cropName: _cropController.text.trim(),
      );

      setState(() => _recommendResult = result);
      await _runExplain(result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        cropName: _cropController.text.trim(),
        issues: issues,
      );
      setState(() => _explainResult = result);
      await _saveToSupabase(recommendResult, result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Explain error: $e')));
    } finally {
      setState(() => _isLoadingExplain = false);
    }
  }

  Future<void> _saveToSupabase(
    Map<String, dynamic> recommend,
    Map<String, dynamic> explain,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Insert and capture the returned scan id
      final inserted = await Supabase.instance.client
          .from('scan_history')
          .insert({
            'user_id': user.id,
            'soil_type': widget.predictResult['soil_type'],
            'om_level': widget.predictResult['om_level'],
            'confidence': widget.predictResult['confidence'],
            'crop_name': _cropController.text.trim(),
            'compatibility': recommend['compatibility'],
            'issues': recommend['issues'],
            'amendments': recommend['amendments'],
            'explanation': explain['explanation'],
          })
          .select('id')
          .single();

      setState(() {
        _scanId = inserted['id'] as String;
        _isSaved = true;
        _chatVisible = true; // Show chat only after scan is saved
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final predict = widget.predictResult;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SOIL ANALYSIS ──────────────────────────────────
            const Text('--- SOIL ANALYSIS ---'),
            SizedBox(height: h * 0.01),
            Text('Soil Type: ${predict['soil_type']}'),
            Text('Confidence: ${predict['confidence']}'),
            Text('Organic Matter: ${predict['om_level']}'),
            SizedBox(height: h * 0.02),

            // ── DRAINAGE ───────────────────────────────────────
            if (!_drainageSubmitted) ...[
              const Text('--- HOW DOES WATER BEHAVE IN YOUR SOIL? ---'),
              SizedBox(height: h * 0.01),
              RadioListTile<int>(
                title: const Text('Water pools and stays'),
                value: -1,
                groupValue: _drainageScore,
                onChanged: (v) => setState(() => _drainageScore = v!),
              ),
              RadioListTile<int>(
                title: const Text('Normal absorption'),
                value: 0,
                groupValue: _drainageScore,
                onChanged: (v) => setState(() => _drainageScore = v!),
              ),
              RadioListTile<int>(
                title: const Text('Water drains very fast'),
                value: 1,
                groupValue: _drainageScore,
                onChanged: (v) => setState(() => _drainageScore = v!),
              ),
              SizedBox(height: h * 0.01),
              SizedBox(
                width: w,
                height: h * 0.06,
                child: ElevatedButton(
                  onPressed: () => setState(() => _drainageSubmitted = true),
                  child: const Text('Confirm Drainage'),
                ),
              ),
            ] else if (widget.scanId == null) ...[
              Text(
                'Drainage: ${_drainageScore == -1
                    ? 'Poor'
                    : _drainageScore == 1
                    ? 'Excessive'
                    : 'Normal'}',
              ),
            ],

            SizedBox(height: h * 0.02),

            // ── CROP INPUT ─────────────────────────────────────
            if (_drainageSubmitted && !_cropSubmitted) ...[
              const Text('--- WHAT CROP DO YOU WANT TO PLANT? ---'),
              SizedBox(height: h * 0.01),
              TextField(
                controller: _cropController,
                decoration: const InputDecoration(
                  hintText: 'e.g. rice, mais, kamote',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: h * 0.01),
              SizedBox(
                width: w,
                height: h * 0.06,
                child: _isLoadingRecommend
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _runRecommend,
                        child: const Text('Get Recommendation'),
                      ),
              ),
            ],

            // ── RECOMMENDATION ─────────────────────────────────
            if (_recommendResult != null) ...[
              SizedBox(height: h * 0.02),
              const Text('--- RECOMMENDATION ---'),
              SizedBox(height: h * 0.01),
              Text('Crop: ${_recommendResult!['crop']}'),
              Text('Compatibility: ${_recommendResult!['compatibility']}'),
              SizedBox(height: h * 0.01),
              const Text('Issues:'),
              ...List<String>.from(
                _recommendResult!['issues'],
              ).map((i) => Text('- $i')),
              SizedBox(height: h * 0.01),
              const Text('What to fix:'),
              ...List<String>.from(
                _recommendResult!['amendments'],
              ).map((a) => Text('- $a')),
            ],

            // ── EXPLANATION ────────────────────────────────────
            if (_isLoadingExplain) ...[
              SizedBox(height: h * 0.02),
              const Text('Getting explanation...'),
              const Center(child: CircularProgressIndicator()),
            ],

            if (_explainResult != null) ...[
              SizedBox(height: h * 0.02),
              const Text('--- WHAT HAPPENS IF YOU IGNORE THIS ---'),
              SizedBox(height: h * 0.01),
              Text(_explainResult!['explanation']),
            ],

            if (_isSaved) ...[
              SizedBox(height: h * 0.02),
              const Text('Scan saved successfully.'),
            ],

            // ─────────────────────────────────────────────────────
            // STEP 9 — CHAT SECTION
            // Appears only after scan is saved (scanId exists)
            // ─────────────────────────────────────────────────────
            if (_chatVisible) ...[
              SizedBox(height: h * 0.03),
              const Divider(),
              const Text(
                '--- ASK ABOUT THIS SCAN ---',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: h * 0.01),

              // Message list
              Container(
                height: h * 0.35,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'Ask anything about your soil scan.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _chatScroll,
                        padding: const EdgeInsets.all(8),
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
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(msg['content'] ?? ''),
                            ),
                          );
                        },
                      ),
              ),

              if (_isLoadingChat)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),

              SizedBox(height: h * 0.01),

              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about this soil scan...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoadingChat ? null : _sendChatMessage,
                  ),
                ],
              ),
            ],

            SizedBox(height: h * 0.04),
          ],
        ),
      ),
    );
  }
}
