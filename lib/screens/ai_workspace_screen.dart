import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';
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


  final List<ChatMessage> messages = [];


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


  void sendMessage() {

    final text =
        messageController.text.trim();


    if (text.isEmpty) {
      return;
    }


    setState(() {

      messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );

    });


    messageController.clear();


    Future.delayed(
      const Duration(seconds: 1),
      () {

        setState(() {

          messages.add(
            ChatMessage(
              text:
                  "I will help you understand \"$text\".\n\nAI integration will be added in Phase 4 🚀",
              isUser: false,
            ),
          );

        });

      },
    );
  }



  Widget suggestionChip(String text) {

    return Chip(

      label: Text(text),

      backgroundColor:
          Colors.grey.shade100,
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


                                child:
                                    Text(

                                  message.text,


                                  style:
                                      TextStyle(

                                    color:

                                        message.isUser

                                            ? Colors.white

                                            : Colors.black,
                                  ),
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

                    child:
                        TextField(

                      controller:
                          messageController,


                      decoration:
                          InputDecoration(

                        hintText:
                            "Ask StudyMateAI anything...",


                        filled:
                            true,


                        fillColor:
                            Colors.grey.shade100,


                        border:
                            OutlineInputBorder(

                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),


                          borderSide:
                              BorderSide.none,
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