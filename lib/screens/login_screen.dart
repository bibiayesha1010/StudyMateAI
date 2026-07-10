import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() {

    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email and password"),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome $email"),
        ),
      );

      // Next we will navigate to Home Dashboard here
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Login"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),


            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),


            const SizedBox(height: 20),


            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),


            const SizedBox(height: 30),


            ElevatedButton(

              onPressed: login,

              child: const Text(
                "Login",
              ),
            ),

          ],
        ),
      ),
    );
  }
}