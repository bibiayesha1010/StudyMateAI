import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';


class SignupScreen extends StatefulWidget {

  const SignupScreen({super.key});


  @override
  State<SignupScreen> createState() => _SignupScreenState();

}



class _SignupScreenState extends State<SignupScreen> {


  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();


  bool isLoading = false;



  Future<void> signup() async {

    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();



    if(name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );

      return;
    }



    if(password != confirmPassword){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
        ),
      );

      return;
    }



    setState(() {
      isLoading = true;
    });



    try {


      await AuthService().register(
        email: email,
        password: password,
      );


      if(!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
        ),
      );


      Navigator.pop(context);



    }


    on FirebaseAuthException catch(e){


      if(!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Signup failed",
          ),
        ),
      );


    }


    finally{


      if(mounted){

        setState(() {
          isLoading = false;
        });

      }

    }

  }





  @override
  void dispose(){

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();

  }






  @override
  Widget build(BuildContext context){


    return Scaffold(


      appBar: AppBar(
        title: const Text("Create Account"),
      ),



      body: Padding(

        padding: const EdgeInsets.all(24),


        child: SingleChildScrollView(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,


            children: [


              const SizedBox(height:40),



              const Text(

                "Join StudyMateAI",

                style: TextStyle(

                  fontSize:28,

                  fontWeight:FontWeight.bold,

                ),

              ),



              const SizedBox(height:30),



              TextField(

                controller:nameController,

                decoration:const InputDecoration(

                  labelText:"Name",

                  border:OutlineInputBorder(),

                ),

              ),



              const SizedBox(height:20),



              TextField(

                controller:emailController,

                keyboardType:TextInputType.emailAddress,

                decoration:const InputDecoration(

                  labelText:"Email",

                  border:OutlineInputBorder(),

                ),

              ),



              const SizedBox(height:20),



              TextField(

                controller:passwordController,

                obscureText:true,

                decoration:const InputDecoration(

                  labelText:"Password",

                  border:OutlineInputBorder(),

                ),

              ),



              const SizedBox(height:20),



              TextField(

                controller:confirmPasswordController,

                obscureText:true,

                decoration:const InputDecoration(

                  labelText:"Confirm Password",

                  border:OutlineInputBorder(),

                ),

              ),



              const SizedBox(height:30),



              SizedBox(

                width:double.infinity,

                height:50,


                child:ElevatedButton(

                  onPressed:isLoading ? null : signup,


                  child:isLoading

                  ? const CircularProgressIndicator()

                  : const Text(
                      "Create Account",
                    ),

                ),

              ),



            ],

          ),

        ),

      ),

    );


  }


}