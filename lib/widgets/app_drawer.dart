import 'package:flutter/material.dart';

import '../screens/ai_workspace_screen.dart';
import '../screens/chat_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/welcome_screen.dart';



class AppDrawer extends StatelessWidget {

  final String email;


  const AppDrawer({
    super.key,
    required this.email,
  });




 @override
Widget build(BuildContext context) {

  return Drawer(

    child: SafeArea(

      child: Column(

        children: [

          UserAccountsDrawerHeader(

            accountName: const Text(
              "StudyMate User",
            ),

            accountEmail: Text(email),

            currentAccountPicture: const CircleAvatar(

              child: Icon(
                Icons.person,
              ),

            ),

          ),


         ListTile(

  leading: const Icon(
    Icons.add_comment_outlined,
  ),

  title: const Text(
    "New Chat",
  ),

  onTap: () {

    Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AIWorkspaceScreen(
          email: email,
        ),
      ),
    );

  },

),
          ListTile(

            leading: const Icon(
              Icons.person,
            ),

            title: const Text(
              "Profile",
            ),

            onTap: (){

              Navigator.pop(context);


              Navigator.push(


                context,


                MaterialPageRoute(


                  builder: (context)=> ProfileScreen(

                    email: email,

                  ),


                ),


              );


            },


          ),


            ListTile(



              leading: const Icon(

                Icons.history,

              ),



              title: const Text(

                "Chat History",

              ),



              onTap: (){



                Navigator.pop(context);



                Navigator.push(



                  context,



                  MaterialPageRoute(



                    builder:(context)=> ChatHistoryScreen(

                      email: email,

                    ),



                  ),



                );



              },



            ),








           
            ListTile(



              leading: const Icon(

                Icons.settings,

              ),



              title: const Text(

                "Settings",

              ),



              onTap: (){



                Navigator.pop(context);



                Navigator.push(



                  context,



                  MaterialPageRoute(



                    builder:(context)=> const SettingsScreen(),



                  ),



                );



              },



            ),







            ListTile(



              leading: const Icon(

                Icons.info,

              ),



              title: const Text(

                "About",

              ),



              onTap: (){



                Navigator.pop(context);



                Navigator.push(



                  context,



                  MaterialPageRoute(



                    builder:(context)=> const AboutScreen(),



                  ),



                );



              },



            ),







            const Spacer(),







            const Divider(),








            ListTile(



              leading: const Icon(

                Icons.logout,

              ),



              title: const Text(

                "Logout",

              ),



              onTap: (){



                Navigator.pushAndRemoveUntil(



                  context,



                  MaterialPageRoute(



                    builder:(context)=> const WelcomeScreen(),



                  ),



                  (route)=>false,



                );



              },



            ),





          ],



        ),



      ),



    );



  }



}