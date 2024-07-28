import 'package:firebase_auth/firebase_auth.dart';
import 'package:chronocapsules/Reusable%20Widgets/reusable_widget.dart';
import 'package:chronocapsules/main.dart';
import 'package:chronocapsules/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key}); // Follow Dart conventions for class names

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailOrUidTextController =
      TextEditingController();

  Future<void> _signIn() async {
    String input = _emailOrUidTextController.text.trim();
    String password = _passwordTextController.text;

    try {
      UserCredential userCredential;
      if (input.contains('@')) {
        // Sign in using email
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: input,
          password: password,
        );
      } else {
        // Sign in using custom user ID (we assume the custom user ID is stored in a field called 'customUid')
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('customUid', isEqualTo: input)
            .limit(1)
            .get();

        if (userSnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
              code: 'user-not-found', message: 'User not found.');
        }

        String email = userSnapshot.docs.first['email'];

        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TimeCapsuleHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.black87, Colors.black26],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget("images/chest.png"),
                const SizedBox(
                  height: 30,
                ),
                reusableTextField("Enter Email Address or User ID",
                    Icons.person_outline, false, _emailOrUidTextController),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Password", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(
                  height: 20,
                ),
                signInSignUpButton(
                  context,
                  true,
                  _signIn,
                ),
                signUpOption()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.white),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpScreen(),
              ),
            );
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
