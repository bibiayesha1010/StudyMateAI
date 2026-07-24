import 'package:flutter/material.dart';


class AboutScreen extends StatelessWidget {


  const AboutScreen({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text(
          "About",
        ),

      ),



      body: Padding(


        padding: const EdgeInsets.all(24),



        child: Column(


          crossAxisAlignment: CrossAxisAlignment.start,



          children: [



            const Center(


              child: Icon(

                Icons.school,

                size: 80,

              ),


            ),





            const SizedBox(height: 20),





            const Center(


              child: Text(


                "StudyMateAI",


                style: TextStyle(


                  fontSize: 28,

                  fontWeight: FontWeight.bold,


                ),


              ),


            ),





            const SizedBox(height: 10),





            const Center(


              child: Text(


                "Your AI Study Companion",


                style: TextStyle(

                  fontSize: 18,

                ),


              ),


            ),





            const SizedBox(height: 30),





            const Text(


              "StudyMateAI helps students learn smarter using AI-powered tools.",


              style: TextStyle(

                fontSize: 16,

              ),


            ),





            const SizedBox(height: 20),





            const Text(


              "Features:",


              style: TextStyle(


                fontSize: 18,

                fontWeight: FontWeight.bold,


              ),


            ),





            const SizedBox(height: 10),





            const Text(

              "• Generate study notes\n"
              "• Summarize topics\n"
              "• Understand difficult concepts\n"
              "• AI-powered learning assistance",

              style: TextStyle(

                fontSize: 16,

              ),

            ),





            const Spacer(),





            const Center(


              child: Text(


                "Version 1.0.0",


                style: TextStyle(

                  color: Colors.grey,

                ),


              ),


            ),



          ],


        ),


      ),


    );


  }


}