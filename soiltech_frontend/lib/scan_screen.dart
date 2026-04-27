import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'results_screen.dart';
import 'services/flask_soil_api.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  int _wetDryScore = 0;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _runPredict() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final predictResult = await SoilApi.predict(
        _selectedImage!,
        _wetDryScore,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            predictResult: predictResult,
            imageFile: _selectedImage!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Soil Scan')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STEP 1 — Select soil image'),
            SizedBox(height: h * 0.01),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text('Take Photo'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Pick from Gallery'),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              SizedBox(height: h * 0.01),
              Text('Image: ${_selectedImage!.path.split('/').last}'),
              SizedBox(height: h * 0.01),
              Image.file(
                _selectedImage!,
                height: h * 0.22,
                width: w,
                fit: BoxFit.cover,
              ),
            ],
            SizedBox(height: h * 0.02),
            const Text('STEP 2 — How is your soil right now?'),
            SizedBox(height: h * 0.01),
            RadioListTile<int>(
              title: const Text('Wet'),
              value: -1,
              groupValue: _wetDryScore,
              onChanged: (v) => setState(() => _wetDryScore = v!),
            ),
            RadioListTile<int>(
              title: const Text('Normal'),
              value: 0,
              groupValue: _wetDryScore,
              onChanged: (v) => setState(() => _wetDryScore = v!),
            ),
            RadioListTile<int>(
              title: const Text('Dry'),
              value: 1,
              groupValue: _wetDryScore,
              onChanged: (v) => setState(() => _wetDryScore = v!),
            ),
            SizedBox(height: h * 0.02),
            SizedBox(
              width: w,
              height: h * 0.06,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _runPredict,
                      child: const Text('Scan Soil'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
