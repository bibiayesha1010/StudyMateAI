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

            currentAccountPicture: CircleAvatar(
              child: Icon(
                Icons.person,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : null,
              ),
            ),

          ),


         ListTile(
  leading: Icon(
    Icons.add_comment_outlined,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.amber
        : null,
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
            leading: Icon(
              Icons.person,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber
                  : null,
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
              leading: Icon(
                Icons.history,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : null,
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
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : null,
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
              leading: Icon(
                Icons.info,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : null,
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
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber
                    : null,
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