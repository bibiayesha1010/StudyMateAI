import 'dart:convert';

import 'package:http/http.dart' as http;

class LocalLLMService {
  // FastAPI local LLM server
  static const String baseUrl = 'http://localhost:8001';

  /// Send a normal chat message to the local Llama model.
  Future<String> sendMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'text': message,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        return 'StudyMate could not get a response from the local AI.';
      }

      final data = jsonDecode(response.body);

      return data['response']?.toString() ??
          'No response received from the local AI.';
    } catch (e) {
      return 'StudyMate could not connect to the local AI. '
          'Make sure the local LLM server is running.';
    }
  }
}