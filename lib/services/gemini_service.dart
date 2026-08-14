import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chatmessage_model.dart';

class GeminiService {
  final String geminiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  // Use a Flash model — this is the one with a genuine free tier
  // for both text and image understanding as of Aug 2026.
  final String model = "gemini-3.5-flash";

  // This shapes how Gemini behaves on every call — tweak freely.
  final String studyMateSystemPrompt = """
You are StudyMate, a friendly and encouraging AI study companion for students.

Your role:
- Help students understand topics clearly, using simple language and examples before technical terms.
- When explaining a concept, break it into small steps rather than one dense paragraph.
- When asked to summarize or generate notes, use headings and bullet points so it's easy to revise from.
- If a student uploads an image (like a textbook page, diagram, or handwritten notes), read it carefully and connect your answer to what's actually in the image.
- Encourage good study habits — suggest a follow-up question or a way to self-test when it fits naturally, but don't be preachy about it.
- Keep answers focused and skimmable. Avoid long-winded intros like "Great question!" — just help.
- If you don't know something or the image is unclear, say so plainly rather than guessing.
""";

  /// Sends [message] (optionally with an [image]) to Gemini, including
  /// [history] — the prior messages in this conversation — so the model
  /// has full context every time, whether the turn is text or image.
  Future<String> sendMessage(
    String message, {
    XFile? image,
    List<ChatMessage> history = const [],
  }) async {
    try {
      final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey",
      );

      // Build the "contents" array from prior turns first...
      final contents = <Map<String, dynamic>>[];

      for (final msg in history) {
        contents.add({
          "role": msg.isUser ? "user" : "model",
          "parts": [
            {"text": msg.text},
          ],
        });
      }

      // ...then add the current turn.
      final currentParts = <Map<String, dynamic>>[
        {"text": message},
      ];

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        currentParts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Image,
          },
        });
      }

      contents.add({
        "role": "user",
        "parts": currentParts,
      });

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {"text": studyMateSystemPrompt},
            ],
          },
          "contents": contents,
        }),
      );

      debugPrint("GEMINI STATUS: ${response.statusCode}");
      debugPrint("GEMINI RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        return "Gemini Error: ${response.body}";
      }

      final data = jsonDecode(response.body);

      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "No response received.";
    } catch (e) {
      debugPrint("GEMINI ERROR: $e");
      return "Error: $e";
    }
  }
}