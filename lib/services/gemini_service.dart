import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chatmessage_model.dart';
import '../models/quiz_model.dart';

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
- Don't open with a bulleted list of things the student "can do" (like "upload a photo" or "ask me to quiz you") — the app already shows those as buttons above the input box, so repeating them is redundant. Just respond naturally to whatever the student actually asked or sent.
""";

  /// Sends [message] (optionally with an [image] and/or a [pdfBytes]
  /// PDF) to Gemini, including [history] so context carries over.
  Future<String> sendMessage(
    String message, {
    XFile? image,
    Uint8List? pdfBytes,
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

      if (pdfBytes != null) {
        final base64Pdf = base64Encode(pdfBytes);

        currentParts.add({
          "inline_data": {
            "mime_type": "application/pdf",
            "data": base64Pdf,
          },
        });
      }

      contents.add({
        "role": "user",
        "parts": currentParts,
      });

      final requestBody = jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": studyMateSystemPrompt},
          ],
        },
        "contents": contents,
        "generationConfig": {
          "thinkingConfig": {"thinkingBudget": 0},
        },
      });

      debugPrint("GEMINI REQUEST BODY: $requestBody");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
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

  /// Generates a quiz as real, structured data (not chat prose) so
  /// scoring can be computed exactly, client-side, with no ambiguity.
  /// [content] is the topic or the notes/explanation text to quiz on.
  /// [image] can optionally be included (e.g. a textbook page) so the
  /// quiz is grounded in exactly what was uploaded.
  Future<QuizModel> generateQuiz(
    String content, {
    XFile? image,
    int numQuestions = 5,
  }) async {
    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey",
    );

    final prompt = """
Based on the following study content, create a $numQuestions-question multiple-choice quiz.

Content:
$content

Respond with ONLY valid JSON, no markdown code fences, no extra commentary, in exactly this shape:
{
  "topic": "short topic name",
  "questions": [
    {
      "question": "the question text",
      "options": ["option A", "option B", "option C", "option D"],
      "correctIndex": 0,
      "explanation": "one short sentence on why that's correct"
    }
  ]
}
""";

    final parts = <Map<String, dynamic>>[
      {"text": prompt},
    ];

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      parts.add({
        "inline_data": {
          "mime_type": "image/jpeg",
          "data": base64Image,
        },
      });
    }

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": parts,
          },
        ],
      }),
    );

    debugPrint("GEMINI QUIZ STATUS: ${response.statusCode}");
    debugPrint("GEMINI QUIZ RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Quiz generation failed: ${response.body}");
    }

    final data = jsonDecode(response.body);

    String text =
        data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

    // Gemini sometimes wraps JSON in ```json fences even when asked not to.
    text = text.trim();
    if (text.startsWith("```")) {
      text = text
          .replaceFirst(RegExp(r'^```json'), '')
          .replaceFirst(RegExp(r'^```'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }

    final quizJson = jsonDecode(text);

    return QuizModel.fromJson(quizJson);
  }
}