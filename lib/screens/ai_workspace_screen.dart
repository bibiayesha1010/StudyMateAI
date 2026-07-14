import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/gemini_service.dart';
import 'package:flutter/services.dart';

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
);

setState(() {
  messages.add(aiMessage);

  ChatService.instance.addMessage(
    currentConversation!,
    aiMessage,
  );
});
}



  Widget suggestionChip(String text) {

  return ActionChip(

    label: Text(text),

    backgroundColor:
        Colors.grey.shade100,

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
  title: const Text("StudyMateAI"),

  backgroundColor: Colors.white,

  foregroundColor: Colors.black,

  elevation: 0,

  actions: [

    IconButton(
      icon: const Icon(Icons.add_comment_outlined),

      tooltip: "New Chat",

      onPressed: () {

        setState(() {

          messages.clear();

          currentConversation = null;

        });

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



            const Padding(

              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),


              child: Align(

                alignment:
                    Alignment.centerLeft,


                child: Text(

                  "How can I help you study today?",


                  style:
                      TextStyle(

                    fontSize: 16,

                    color:
                        Colors.grey,
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

                              Container(

                                height: 90,

                                width: 90,


                                decoration:
                                    BoxDecoration(

                                  color:
                                      Colors.blue.shade50,

                                  shape:
                                      BoxShape.circle,
                                ),


                                child:
                                    const Icon(

                                  Icons.auto_awesome,

                                  size: 45,

                                  color:
                                      Colors.blue,
                                ),
                              ),



                              const SizedBox(
                                height: 20,
                              ),



                              const Text(

                                "Start a conversation with StudyMateAI",

                                style:
                                    TextStyle(

                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),



                              const SizedBox(
                                height: 20,
                              ),



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
                                    const EdgeInsets.all(14),


                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 300,
                                ),


                                decoration:
                                    BoxDecoration(

                                  color:

                                      message.isUser

                                          ? Colors.blue

                                          : Colors.grey.shade200,


                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),


                               child: Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Flexible(
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser
              ? Colors.white
              : Colors.black,
        ),
      ),
    ),

    if (!message.isUser)
      IconButton(
        icon: const Icon(
          Icons.copy,
          size: 18,
        ),

        onPressed: () {

          Clipboard.setData(
            ClipboardData(
              text: message.text,
            ),
          );

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Copied!",
              ),
            ),
          );
        },
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
      hintText: "Ask StudyMateAI anything...",
      filled: true,
      fillColor: Colors.grey.shade100,
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