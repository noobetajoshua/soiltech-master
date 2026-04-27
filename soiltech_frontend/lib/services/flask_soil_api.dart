import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'http://10.0.2.2:5000';

class SoilApi {
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

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  static Future<Map<String, dynamic>> recommend({
    required String soilType,
    required String omLevel,
    required int drainageScore,
    required String cropName,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'soil_type': soilType,
        'om_level': omLevel,
        'drainage_score': drainageScore,
        'crop_name': cropName,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> explain({
    required String soilType,
    required String omLevel,
    required String cropName,
    required List<String> issues,
  }) async {
    final uri = Uri.parse('$baseUrl/explain');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'soil_type': soilType,
        'om_level': omLevel,
        'crop_name': cropName,
        'issues': issues,
      }),
    );
    return jsonDecode(response.body);
  }
}
