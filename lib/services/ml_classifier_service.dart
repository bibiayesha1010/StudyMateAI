import 'dart:convert';
import 'package:http/http.dart' as http;

class MLClassifierService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> classify(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classify'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'ML classifier failed: ${response.statusCode} ${response.body}',
    );
  }
}