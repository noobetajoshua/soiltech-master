import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/flask_soil_api.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> predictResult;
  final File imageFile;

  const ResultsScreen({
    super.key,
    required this.predictResult,
    required this.imageFile,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _drainageScore = 0;
  bool _drainageSubmitted = false;

  final TextEditingController _cropController = TextEditingController();
  bool _cropSubmitted = false;

  Map<String, dynamic>? _recommendResult;
  Map<String, dynamic>? _explainResult;

  bool _isLoadingRecommend = false;
  bool _isLoadingExplain = false;
  bool _isSaved = false;

  Future<void> _runRecommend() async {
    if (_cropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a crop name')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Explain error: $e')));
    } finally {
      setState(() => _isLoadingExplain = false);
    }
  }

  Future<void> _saveToSupabase(
      Map<String, dynamic> recommend, Map<String, dynamic> explain) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('scan_history').insert({
        'user_id': user.id,
        'soil_type': widget.predictResult['soil_type'],
        'om_level': widget.predictResult['om_level'],
        'confidence': widget.predictResult['confidence'],
        'crop_name': _cropController.text.trim(),
        'compatibility': recommend['compatibility'],
        'issues': recommend['issues'],
        'amendments': recommend['amendments'],
        'explanation': explain['explanation'],
      });

      setState(() => _isSaved = true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final predict = widget.predictResult;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical: h * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('--- SOIL ANALYSIS ---'),
            SizedBox(height: h * 0.01),
            Text('Soil Type: ${predict['soil_type']}'),
            Text('Confidence: ${predict['confidence']}'),
            Text('Organic Matter: ${predict['om_level']}'),
            SizedBox(height: h * 0.02),

            // DRAINAGE INPUT
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
            ] else ...[
              Text(
                'Drainage: ${_drainageScore == -1 ? 'Poor' : _drainageScore == 1 ? 'Excessive' : 'Normal'}',
              ),
            ],

            SizedBox(height: h * 0.02),

            // CROP INPUT
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

            // RECOMMENDATION RESULTS
            if (_recommendResult != null) ...[
              SizedBox(height: h * 0.02),
              const Text('--- RECOMMENDATION ---'),
              SizedBox(height: h * 0.01),
              Text('Crop: ${_recommendResult!['crop']}'),
              Text('Compatibility: ${_recommendResult!['compatibility']}'),
              SizedBox(height: h * 0.01),
              const Text('Issues:'),
              ...List<String>.from(_recommendResult!['issues'])
                  .map((i) => Text('- $i')),
              SizedBox(height: h * 0.01),
              const Text('What to fix:'),
              ...List<String>.from(_recommendResult!['amendments'])
                  .map((a) => Text('- $a')),
            ],

            // EXPLANATION
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

            // SAVE STATUS
            if (_isSaved) ...[
              SizedBox(height: h * 0.02),
              const Text('Scan saved successfully.'),
            ],

            SizedBox(height: h * 0.04),
          ],
        ),
      ),
    );
  }
}