import 'package:flutter/material.dart';

import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import 'ai_workspace_screen.dart';

class ChatHistoryScreen extends StatefulWidget {

  final String email;

  const ChatHistoryScreen({
    super.key,
    required this.email,
  });


  @override
  State<ChatHistoryScreen> createState() =>
      _ChatHistoryScreenState();

}



class _ChatHistoryScreenState
    extends State<ChatHistoryScreen>{



  @override
  Widget build(BuildContext context){


    final List<Conversation> conversations =
    ChatService.instance.conversations.reversed.toList();



    return Scaffold(


      appBar:AppBar(

        title:
        const Text(
          "Chat History",
        ),

        centerTitle:true,

      ),



      body:

      conversations.isEmpty

          ?

      const Center(

        child:Text(
          "No conversations yet",
          style:
          TextStyle(
            fontSize:18,
          ),
        ),

      )


          :

      ListView.builder(

        itemCount:
        conversations.length,


        itemBuilder:
            (context,index){


          final conversation =
          conversations[index];



          return Card(

            margin:
            const EdgeInsets.all(12),



            child:ListTile(


              leading:
              const CircleAvatar(

                child:
                Icon(
                  Icons.chat,
                ),

              ),



              title:
              Text(
                conversation.title,
              ),



              subtitle:
              Text(
                "${conversation.updatedAt.day}/${conversation.updatedAt.month}/${conversation.updatedAt.year}",
              ),



              onTap:(){


                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        AIWorkspaceScreen(

                          email:
                          widget.email,

                          conversation:
                          conversation,

                        ),

                  ),

                );


              },

            ),

          );


        },

      ),

    );

  }


}