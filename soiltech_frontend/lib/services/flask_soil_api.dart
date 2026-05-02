import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// LOCAL — emulator
const String baseUrl = 'http://10.0.2.2:5000';

// PRODUCTION — Render
//const String baseUrl = 'https://your-app.onrender.com';

// 60 seconds — handles Render cold start wake-up delay
const Duration _timeout = Duration(seconds: 60);

class SoilApi {
  // ─────────────────────────────────────────────
  // PREDICT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> predict(
    File imageFile,
    int wetDryScore,
  ) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    request.fields['wet_dry_score'] = wetDryScore.toString();

    final streamedResponse = await request.send().timeout(_timeout);
    final body = await streamedResponse.stream.bytesToString();
    return jsonDecode(body);
  }

  // ─────────────────────────────────────────────
  // RECOMMEND
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> recommend({
    required String soilType,
    required String omLevel,
    required int drainageScore,
    required String cropName,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'soil_type': soilType,
            'om_level': omLevel,
            'drainage_score': drainageScore,
            'crop_name': cropName,
          }),
        )
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  // ─────────────────────────────────────────────
  // EXPLAIN
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> explain({
    required String soilType,
    required String omLevel,
    required String cropName,
    required List<String> issues,
    required String farmerName,
  }) async {
    final uri = Uri.parse('$baseUrl/explain');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'soil_type': soilType,
            'om_level': omLevel,
            'crop_name': cropName,
            'issues': issues,
            'farmer_name': farmerName,
          }),
        )
        .timeout(_timeout);
    return jsonDecode(response.body);
  }

  // ─────────────────────────────────────────────
  // CHAT
  // ─────────────────────────────────────────────
  static Future<String> chat({
    required String soilType,
    required String omLevel,
    required String cropName,
    required List<String> amendments,
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
    required String farmerName,
  }) async {
    final uri = Uri.parse('$baseUrl/chat');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'soil_type': soilType,
            'om_level': omLevel,
            'crop_name': cropName,
            'amendments': amendments,
            'conversation_history': conversationHistory,
            'user_message': userMessage,
            'farmer_name': farmerName,
          }),
        )
        .timeout(_timeout);

    final decoded = jsonDecode(response.body);
    if (decoded['error'] != null) throw Exception(decoded['error']);
    return decoded['reply'] as String;
  }
}
