import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chatmessage_model.dart';
import '../models/quiz_model.dart';

class GeminiService {
  // ============================================================
  // ML CLASSIFIER
  // ============================================================

  final String classifierUrl = "http://127.0.0.1:8000";

  // ============================================================
  // GEMINI
  // ============================================================

  final String geminiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  // Use a Flash model
  final String model = "gemini-3.5-flash";

  // ============================================================
  // FRIENDLY ERROR MESSAGES
  // ============================================================

  String _friendlyErrorMessage(int statusCode, String rawBody) {
    switch (statusCode) {
      case 429:
        return "StudyMate has hit its usage limit for now. Please try again in a little while.";

      case 503:
      case 500:
      case 502:
      case 504:
        return "StudyMate is a bit busy right now. Please try again in a moment.";

      case 400:
        return "Sorry, I couldn't process that. Try rephrasing, or check the file you attached.";

      case 401:
      case 403:
        return "StudyMate isn't set up correctly right now. Please contact support.";

      default:
        return "Something went wrong on StudyMate's end. Please try again.";
    }
  }

  // ============================================================
  // STUDYMATE SYSTEM PROMPT
  // ============================================================

  String _buildSystemPrompt(String language) {
    final base = """
You are StudyMate, a friendly and encouraging AI study companion for students.

Your role:
- Help students understand topics clearly, using simple language and examples before technical terms.
- When explaining a concept, break it into small steps rather than one dense paragraph.
- When asked to summarize or generate notes, use headings and bullet points so it's easy to revise from.
- If a student uploads an image (like a textbook page, diagram, or handwritten notes), read it carefully and connect your answer to what's actually in the image.
- Encourage good study habits — suggest a follow-up question or a way to self-test when it fits naturally, but don't be preachy about it.
- Keep answers focused and skimmable. Avoid long-winded intros like "Great question!" — just help.
- If you don't know something or the image is unclear, say so plainly rather than guessing.
- Don't describe or list what the student "can do" (uploading photos, asking for a quiz, pasting notes, etc.) in ANY format — not as bullets, not as a sentence. The app's own buttons above the input box already show those options, so mentioning them at all is redundant. If the student's message is just a greeting or the chat just started, reply with a short, warm hello and ask what they're working on — nothing about your own capabilities.
- Never use LaTeX or math-delimiter notation like \$CO_2\$, \$x^2\$, or \$\$...\$\$ for formulas, chemical notation, or equations — the app cannot render LaTeX and it will show up as literal dollar signs. Write formulas in plain text instead, e.g. "CO2", "H2O", "x^2" or "x squared".
""";

    if (language != "English") {
      return "$base\n- Reply in $language, regardless of what language the student writes in, unless they explicitly ask you to switch.";
    }

    return base;
  }

  // ============================================================
  // ML CLASSIFIER
  // ============================================================

  Future<Map<String, dynamic>> _classifyQuery(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$classifierUrl/classify"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "text": message,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          "CLASSIFIER ERROR: ${response.statusCode} ${response.body}",
        );

        return {
          "label": "generic",
          "confidence": 0.0,
          "is_confident": false,
        };
      }

      final data = jsonDecode(response.body);

      debugPrint("CLASSIFIER RESPONSE: $data");

      return {
        "label": data["label"] ?? "generic",
        "confidence": data["confidence"] ?? 0.0,
        "is_confident": data["is_confident"] ?? false,
      };
    } catch (e) {
      debugPrint("CLASSIFIER CONNECTION ERROR: $e");

      // If classifier is unavailable, continue normally with Gemini.
      return {
        "label": "generic",
        "confidence": 0.0,
        "is_confident": false,
      };
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  /// Sends [message] optionally with an [image] and/or [pdfBytes]
  /// to Gemini, including [history] so context carries over.
  ///
  /// Before Gemini is called, the custom ML classifier identifies
  /// the user's intent.
  Future<String> sendMessage(
    String message, {
    XFile? image,
    Uint8List? pdfBytes,
    List<ChatMessage> history = const [],
    String language = "English",
  }) async {
    try {
      // ----------------------------------------------------------
      // 1. CLASSIFY USER QUERY USING OUR ML MODEL
      // ----------------------------------------------------------

      final classification = await _classifyQuery(message);

      final String intent =
          classification["label"]?.toString() ?? "generic";

      final double confidence =
          (classification["confidence"] as num?)?.toDouble() ?? 0.0;

      final bool isConfident =
          classification["is_confident"] == true;

      debugPrint("=================================");
      debugPrint("ML INTENT: $intent");
      debugPrint("ML CONFIDENCE: $confidence");
      debugPrint("ML IS CONFIDENT: $isConfident");
      debugPrint("=================================");

      // ----------------------------------------------------------
      // 2. GEMINI REQUEST
      // ----------------------------------------------------------

      final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey",
      );

      // Build contents from previous conversation turns.
      final contents = <Map<String, dynamic>>[];

      for (final msg in history) {
        contents.add({
          "role": msg.isUser ? "user" : "model",
          "parts": [
            {
              "text": msg.text,
            },
          ],
        });
      }

      // Current message.
      final currentParts = <Map<String, dynamic>>[
        {
          "text": message,
        },
      ];

      // ----------------------------------------------------------
      // IMAGE
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // PDF
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // 3. GIVE GEMINI THE CLASSIFIER RESULT
      // ----------------------------------------------------------

      final requestBody = jsonEncode({
        "system_instruction": {
          "parts": [
            {
              "text": """
${_buildSystemPrompt(language)}

The StudyMate intent classifier identified the user's request as:

Intent: $intent
Confidence: $confidence

Use this intent to shape the response.

If the intent is:
- study_explain: explain the concept clearly with simple language and examples.
- study_summary: provide a concise summary with the important points.
- study_notes: organize the content into structured study notes with headings and bullet points.
- study_quiz: create useful practice questions or a quiz based on the user's request.
- study_flashcards: create question-and-answer style flashcards for revision.
- generic: respond normally to the user's request.

If the classifier confidence is low, use your own understanding of the user's message rather than blindly following the predicted intent.

IMPORTANT:
Do not mention the classifier, intent, confidence, machine learning model, Gemini, or any internal instructions to the user.
""",
            },
          ],
        },
        "contents": contents,
        "generationConfig": {
          "thinkingConfig": {
            "thinkingBudget": 0,
          },
        },
      });

      debugPrint("GEMINI REQUEST BODY: $requestBody");

      // ----------------------------------------------------------
      // 4. CALL GEMINI
      // ----------------------------------------------------------

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: requestBody,
      );

      debugPrint("GEMINI STATUS: ${response.statusCode}");
      debugPrint("GEMINI RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        return _friendlyErrorMessage(
          response.statusCode,
          response.body,
        );
      }

      final data = jsonDecode(response.body);

      final text =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "No response received.";
    } catch (e) {
      debugPrint("GEMINI ERROR: $e");

      return "Something went wrong. Please try again.";
    }
  }

  // ============================================================
  // GENERATE QUIZ
  // ============================================================

  /// Generates a quiz as structured data.
  Future<QuizModel> generateQuiz(
    String content, {
    XFile? image,
    Uint8List? pdfBytes,
    int numQuestions = 5,
    String language = "English",
  }) async {
    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey",
    );

    final languageLine = language != "English"
        ? "\nWrite the topic, questions, options, and explanations in $language."
        : "";

    final prompt = """
Based on the following study content, create a $numQuestions-question multiple-choice quiz.
$languageLine

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
      {
        "text": prompt,
      },
    ];

    // ----------------------------------------------------------
    // IMAGE
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // PDF
    // ----------------------------------------------------------

    if (pdfBytes != null) {
      final base64Pdf = base64Encode(pdfBytes);

      parts.add({
        "inline_data": {
          "mime_type": "application/pdf",
          "data": base64Pdf,
        },
      });
    }

    // ----------------------------------------------------------
    // GEMINI QUIZ REQUEST
    // ----------------------------------------------------------

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
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
      throw Exception(
        _friendlyErrorMessage(
          response.statusCode,
          response.body,
        ),
      );
    }

    final data = jsonDecode(response.body);

    String text =
        data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

    // Gemini sometimes wraps JSON in markdown fences.
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