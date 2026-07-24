import 'package:flutter/material.dart';


class PrivacyScreen extends StatelessWidget {


  const PrivacyScreen({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text(
          "Privacy",
        ),

      ),



      body: ListView(


        children: [



          ListTile(


            leading: const Icon(
              Icons.security,
            ),


            title: const Text(
              "Data Privacy",
            ),


            subtitle: const Text(
              "Learn how your data is protected",
            ),



            onTap: (){


              showDialog(


                context: context,


                builder: (context){


                  return AlertDialog(


                    title: const Text(
                      "Data Privacy",
                    ),



                    content: const Text(

                      "StudyMateAI stores your account information securely. "
                      "Your data is used only to provide app features.",

                    ),



                    actions: [


                      TextButton(


                        onPressed: (){


                          Navigator.pop(context);


                        },


                        child: const Text(
                          "OK",
                        ),


                      ),


                    ],


                  );


                },


              );


            },


          ),







          ListTile(


            leading: const Icon(
              Icons.storage,
            ),



            title: const Text(
              "Data Usage",
            ),



            subtitle: const Text(
              "Manage how your data is used",
            ),



            onTap: (){


              showDialog(


                context: context,


                builder: (context){


                  return AlertDialog(


                    title: const Text(
                      "Data Usage",
                    ),



                    content: const Text(

                      "Your chats and preferences are used to improve your StudyMateAI experience.",

                    ),



                    actions: [


                      TextButton(


                        onPressed: (){


                          Navigator.pop(context);


                        },


                        child: const Text(
                          "OK",
                        ),


                      ),


                    ],


                  );


                },


              );


            },


          ),







          ListTile(


            leading: const Icon(
              Icons.delete,
            ),



            title: const Text(
              "Delete Account",
            ),



            subtitle: const Text(
              "Remove your StudyMateAI account",
            ),



            onTap: (){


              showDialog(


                context: context,


                builder: (context){


                  return AlertDialog(


                    title: const Text(
                      "Delete Account",
                    ),



                    content: const Text(

                      "Account deletion feature will be available soon.",

                    ),



                    actions: [


                      TextButton(


                        onPressed: (){


                          Navigator.pop(context);


                        },


                        child: const Text(
                          "OK",
                        ),


                      ),


                    ],


                  );


                },


              );


            },


          ),



        ],


      ),


    );


  }


}