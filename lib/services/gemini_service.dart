import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {

  final String apiKey =
      dotenv.env['GROQ_API_KEY'] ?? "";


  Future<String> sendMessage(String message) async {

    try {

      final response = await http.post(
        Uri.parse(
          "https://api.groq.com/openai/v1/chat/completions",
        ),

        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "model": "llama-3.1-8b-instant",

          "messages": [
            {
              "role": "user",
              "content": message,
            }
          ],

        }),
      );


      final data = jsonDecode(response.body);


      if (data["choices"] != null) {
        return data["choices"][0]["message"]["content"];
      }


      return "No response received.";


    } catch (e) {

      return "Error: $e";

    }
  }
}