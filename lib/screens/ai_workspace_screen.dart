import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/gemini_service.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';


class AIWorkspaceScreen extends StatefulWidget {


  final String email;


  final Conversation? conversation;



  const AIWorkspaceScreen({

    super.key,

    required this.email,

    this.conversation,

  });



  @override
  State<AIWorkspaceScreen> createState() =>
      _AIWorkspaceScreenState();


}


class _AIWorkspaceScreenState
    extends State<AIWorkspaceScreen> {

  final TextEditingController messageController =
      TextEditingController();

      final GeminiService geminiService = GeminiService();


  final List<ChatMessage> messages = [];
Conversation? currentConversation;

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning ☀️";
    } else if (hour < 17) {
      return "Good Afternoon 🌤";
    } else {
      return "Good Evening 🌙";
    }
  }
@override
void initState() {
  super.initState();

  if (widget.conversation != null) {
    currentConversation = widget.conversation;
    messages.addAll(widget.conversation!.messages);
  }
}

 Future<void> sendMessage() async {
  final text = messageController.text.trim();

  if (text.isEmpty) return;

  final userMessage = ChatMessage(
    text: text,
    isUser: true,
     timestamp: DateTime.now(),
  );

  setState(() {
    messages.add(userMessage);

    if (currentConversation == null) {
      currentConversation =
          ChatService.instance.createConversation(text);
    } else {
      ChatService.instance.addMessage(
        currentConversation!,
        userMessage,
      );
    }
  });

  messageController.clear();

 final response =
    await geminiService.sendMessage(text);

final aiMessage = ChatMessage(
  text: response,
  isUser: false,
   timestamp: DateTime.now(),
);

setState(() {
  messages.add(aiMessage);

  ChatService.instance.addMessage(
    currentConversation!,
    aiMessage,
  );
});
}
Future<void> exportPDF() async {

  debugPrint("PDF EXPORT STARTED");

  final pdf = pw.Document();

  final chat = messages
      .map((m) =>
          "${m.isUser ? "You" : "AI"}: ${m.text}")
      .join("\n\n");

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Text(chat),
        );
      },
    ),
  );

  final bytes = await pdf.save();

  await Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        name: "StudyMate_Chat.pdf",
        mimeType: "application/pdf",
      ),
    ],
    text: "StudyMate Chat PDF",
  );
}
  Widget suggestionChip(String text) {

  return ActionChip(

    label: Text(text),

   backgroundColor:
    Theme.of(context).cardColor,

    onPressed: () {

  String title = "";
  String hint = "";
  String promptPrefix = "";
  String buttonText = "";

  if (text == "Generate Notes") {

    title = "Generate Notes";
    hint = "Enter topic";
    buttonText = "Generate";

    promptPrefix =
        "Generate detailed study notes for ";

  } else if (text == "Explain Topic") {

    title = "Explain Topic";
    hint = "Enter topic";
    buttonText = "Explain";

    promptPrefix =
        "Explain the topic ";

  } else if (text == "Summarize") {

    title = "Summarize";
    hint = "Paste notes or enter topic";
    buttonText = "Summarize";

    promptPrefix =
        "Summarize the following content:\n\n";

  }

  final controller = TextEditingController();

  showDialog(

    context: context,

    builder: (context) {

      return AlertDialog(

        title: Text(title),

        content: TextField(

          controller: controller,

          maxLines: text == "Summarize" ? 6 : 1,

          decoration: InputDecoration(
            hintText: hint,
          ),
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context);

            },

            child: const Text("Cancel"),

          ),

          ElevatedButton(

            onPressed: () {

              final input =
                  controller.text.trim();

              if (input.isEmpty) return;

              Navigator.pop(context);

              messageController.text =
                  promptPrefix + input;

              sendMessage();

            },

            child: Text(buttonText),

          ),

        ],

      );

    },

  );

},
  );
}


  @override
  void dispose() {

    messageController.dispose();

    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

   return Scaffold(
drawer: AppDrawer(
  email: widget.email,
),

 appBar: AppBar(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,

  foregroundColor: Theme.of(context).colorScheme.onSurface,

  elevation: 0,

  title: const SizedBox.shrink(),

  actions: [

  IconButton(
    icon: const Icon(Icons.favorite_border_outlined),
    tooltip: "Favorite",
    onPressed: () {

    },
  ),

  IconButton(
    icon: const Icon(Icons.ios_share_outlined),
    tooltip: "Share",
    onPressed: () {

      showModalBottomSheet(

        context: context,

        shape: const RoundedRectangleBorder(

          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),

        ),

        builder: (context) {

          return SafeArea(

            child: Padding(

              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                 ListTile(
  leading: const Icon(Icons.copy),
  title: const Text("Copy Chat"),
  onTap: () {
    final chat = messages
        .map((m) => "${m.isUser ? "You" : "StudyMate"}: ${m.text}")
        .join("\n\n");

    Clipboard.setData(
      ClipboardData(text: chat),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Chat copied to clipboard."),
      ),
    );
  },
),
                  const ListTile(

                    leading: Icon(Icons.image_outlined),

                    title: Text("Share as Image"),

                  ),

                 ListTile(

  leading: const Icon(Icons.picture_as_pdf_outlined),

  title: const Text("Export as PDF"),

  onTap: () {
 debugPrint("PDF BUTTON CLICKED");
    Navigator.pop(context);

    exportPDF();

  },

),

                 ListTile(

  leading: const Icon(Icons.share_outlined),

  title: const Text("Share via Apps"),

  onTap: () {

    final chat = messages
        .map((m) =>
            "${m.isUser ? "You" : "AI"}: ${m.text}")
        .join("\n\n");

    Navigator.pop(context);

    Share.share(
      chat,
      subject: "StudyMate Chat",
    );

  },

),

                  const Divider(),

                  ListTile(

                    leading: const Icon(Icons.close),

                    title: const Text("Cancel"),

                    onTap: () {

                      Navigator.pop(context);

                    },

                  ),

                ],

              ),

            ),

          );

        },

      );

    },

  ),

],
),

  body: SafeArea(

        child: Column(

          children: [


            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                8,
              ),


              child: Align(

                alignment:
                    Alignment.centerLeft,


                child: Text(

                  getGreeting(),


                  style:
                      const TextStyle(

                    fontSize: 28,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),



             Padding(

              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),


              child: Align(

                alignment:
                    Alignment.centerLeft,


                child: Text(

                  "How may I assist you today?",


                  style:
                      TextStyle(

                    fontSize: 16,

                  color:
    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),



            const SizedBox(
              height: 20,
            ),




            Expanded(

              child:

                  messages.isEmpty

                      ? Center(

                          child: Column(

                            mainAxisAlignment:
                                MainAxisAlignment.center,


                            children: [



                              Wrap(

                                spacing: 10,

                                children: [

                                  suggestionChip(
                                    "Generate Notes",
                                  ),

                                  suggestionChip(
                                    "Explain Topic",
                                  ),

                                  suggestionChip(
                                    "Summarize",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )


                      : ListView.builder(

                          padding:
                              const EdgeInsets.all(16),


                          itemCount:
                              messages.length,


                          itemBuilder:
                              (context, index) {

                            final message =
                                messages[index];


                            return Align(

                              alignment:

                                  message.isUser

                                      ? Alignment.centerRight

                                      : Alignment.centerLeft,


                              child: Container(

                                margin:
                                    const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),


                                padding:
                                    const EdgeInsets.all(10),


                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 300,
                                ),


                                decoration:
                                    BoxDecoration(

                                  color:

                                      message.isUser

                                          ? Colors.blue

                                         : Theme.of(context).cardColor,


                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),


                              child: Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [

    Flexible(
      child: SelectableText(
        message.text,
        style: TextStyle(
          color: message.isUser
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),

  ],
),
                              ),
                            );
                          },
                        ),
            ),




            const Divider(
              height: 1,
            ),




            Padding(

              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                16,
              ),


              child: Row(

                children: [


                  IconButton(

                    icon:
                        const Icon(
                      Icons.add_circle_outline,
                    ),

                    onPressed: () {},
                  ),



                 Expanded(
  child: TextField(
    controller: messageController,
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => sendMessage(),
    decoration: InputDecoration(
      hintText: "Ask anything...",
      filled: true,
     fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),



                  IconButton(

                    icon:
                        const Icon(
                      Icons.mic_none,
                    ),

                    onPressed: () {},
                  ),



                  Container(

                    decoration:
                        const BoxDecoration(

                      color:
                          Colors.blue,

                      shape:
                          BoxShape.circle,
                    ),


                    child:
                        IconButton(

                      icon:
                          const Icon(

                        Icons.arrow_upward,

                        color:
                            Colors.white,
                      ),


                      onPressed:
                          sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}