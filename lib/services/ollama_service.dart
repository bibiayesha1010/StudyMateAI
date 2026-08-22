import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OllamaService {
  // For Flutter Web/Desktop running on the same laptop.
  static const String baseUrl = "http://localhost:8001";

  Future<String> sendMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/chat"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "text": message,
            }),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint("OLLAMA STATUS: ${response.statusCode}");
      debugPrint("OLLAMA RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        return "StudyMate is having trouble right now. Please try again.";
      }

      final data = jsonDecode(response.body);

      return data["response"]?.toString() ??
          "No response received from StudyMate.";
    } catch (e) {
      debugPrint("OLLAMA ERROR: $e");

      return "StudyMate couldn't connect to the local AI. Please make sure Ollama and the StudyMate server are running.";
    }
  }
}