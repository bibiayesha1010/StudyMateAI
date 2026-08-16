import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import 'privacy_screen.dart';



class SettingsScreen extends StatelessWidget {


  const SettingsScreen({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text(
          "Settings",
        ),

      ),



      body: ListView(


        children: [



          Consumer<NotificationProvider>(


            builder: (context, notificationProvider, child) {



              return SwitchListTile(


                secondary: const Icon(
                  Icons.notifications,
                ),



                title: const Text(
                  "Notifications",
                ),



                subtitle: const Text(
                  "Receive study reminders",
                ),



                value: notificationProvider.notificationsEnabled,



                onChanged: (value){


                  notificationProvider.toggleNotifications(value);


                },


              );


            },


          ),







          Consumer<ThemeProvider>(


            builder: (context, themeProvider, child) {



              return SwitchListTile(


                secondary: const Icon(
                  Icons.dark_mode,
                ),



                title: const Text(
                  "Dark Mode",
                ),



                subtitle: const Text(
                  "Change app appearance",
                ),



                value: themeProvider.isDarkMode,



                onChanged: (value){



                  themeProvider.toggleTheme(value);



                },



              );


            },



          ),








          ListTile(


            leading: const Icon(
              Icons.lock,
            ),



            title: const Text(
              "Privacy",
            ),



            subtitle: const Text(
              "Manage your privacy settings",
            ),



            onTap: (){


              Navigator.push(


                context,


                MaterialPageRoute(


                  builder: (context) => const PrivacyScreen(),


                ),


              );


            },


          ),







          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return ListTile(
                leading: const Icon(
                  Icons.language,
                ),
                title: const Text(
                  "Language",
                ),
                subtitle: Text(
                  languageProvider.selectedLanguage,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Select Language"),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: LanguageProvider.supportedLanguages
                                .map((language) {
                              return RadioListTile<String>(
                                title: Text(language),
                                value: language,
                                groupValue:
                                    languageProvider.selectedLanguage,
                                onChanged: (value) {
                                  if (value != null) {
                                    languageProvider.setLanguage(value);
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
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