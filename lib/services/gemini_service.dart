import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {

  static const String apiKey = "YOUR_API_KEY_HERE";

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
  );


  Future<String> sendMessage(String message) async {

    try {

      final response = await model.generateContent(
        [
          Content.text(message),
        ],
      );

      return response.text ??
          "No response generated.";

    } catch (e) {

      return "Error: $e";

    }
  }
}