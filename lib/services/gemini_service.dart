import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class GeminiService {

  final String groqApiKey =
      dotenv.env['GROQ_API_KEY'] ?? "";


  final String openRouterApiKey =
      dotenv.env['OPENROUTER_API_KEY'] ?? "";



  Future<String> sendMessage(
    String message, {
    XFile? image,
  }) async {

    try {


      // ============================
      // IMAGE REQUEST → OPENROUTER
      // ============================

      if (image != null) {


        final bytes =
            await image.readAsBytes();


        final base64Image =
            base64Encode(bytes);



        final response =
            await http.post(

          Uri.parse(
            "https://openrouter.ai/api/v1/chat/completions",
          ),


          headers: {

            "Authorization":
                "Bearer $openRouterApiKey",

            "Content-Type":
                "application/json",

          },


          body: jsonEncode({

        "model":
    "openrouter/free",
   

            "messages": [

              {

                "role": "user",

                "content": [

                  {

                    "type": "text",

                    "text": message,

                  },


                  {

                    "type": "image_url",

                    "image_url": {

                      "url":
                          "data:image/jpeg;base64,$base64Image",

                    },

                  },

                ],

              }

            ],


          }),

        );



        final data =
            jsonDecode(response.body);



        debugPrint(
          "OPENROUTER STATUS: ${response.statusCode}",
        );


        debugPrint(
          "OPENROUTER RESPONSE: ${response.body}",
        );



        if (data["choices"] != null) {

          return data["choices"][0]
              ["message"]["content"];

        }



        if (data["error"] != null) {

          return "OpenRouter Error: ${data["error"]["message"]}";

        }


        return "No image response received.";

      }



      // ============================
      // TEXT REQUEST → GROQ
      // ============================


      final response =
          await http.post(

        Uri.parse(
          "https://api.groq.com/openai/v1/chat/completions",
        ),


        headers: {

          "Authorization":
              "Bearer $groqApiKey",

          "Content-Type":
              "application/json",

        },


        body: jsonEncode({

          "model":
              "llama-3.1-8b-instant",


          "messages": [

            {

              "role": "user",

              "content": message,

            }

          ],


        }),

      );



      final data =
          jsonDecode(response.body);



      debugPrint(
        "GROQ STATUS: ${response.statusCode}",
      );


      debugPrint(
        "GROQ RESPONSE: ${response.body}",
      );



      if (data["choices"] != null) {

        return data["choices"][0]
            ["message"]["content"];

      }



      if (data["error"] != null) {

        return "Groq Error: ${data["error"]["message"]}";

      }



      return "No response received.";



    } catch (e) {


      debugPrint(
        "AI ERROR: $e",
      );


      return "Error: $e";

    }

  }

}