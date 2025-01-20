import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wall/components/button.dart';
import 'package:wall/components/text_field.dart';
import 'package:wall/pages/home_page.dart';
import 'package:wall/styles/text_styles.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmTextController = TextEditingController();

  Future<void> signUp() async {
    if (passwordTextController.text != confirmTextController.text) {
      displayMessage(context, tr('register_error_passwords_dont_match'));
      return;
    }
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email!)
          .set({
        'email': userCredential.user!.email!,
        'username': emailTextController.text.split('@')[0],
        'bio': '-'
      });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      displayMessage(context, e.code);
    }
  }

  void displayMessage(BuildContext context, String message) {
    String errorMessage = tr('register_error_title');
    if (message == "weak-password") {
      errorMessage = tr('register_error_weak_password');
    } else if (message == "email-already-in'use") {
      errorMessage = tr('register_error_email_in_use');
    } else if (message == "invalid-email") {
      errorMessage = tr('register_error_invalid_email');
    } else if (message == "operation-not-allowed") {
      errorMessage = tr('register_error_operation_not_allowed');
    } else if (message == "user-disabled") {
      errorMessage = tr('register_error_user_disabled');
    } else if (message == "too-many-requests") {
      errorMessage = tr('register_error_too_many_requests');
    } else if (message == "passwords-dont-match") {
      errorMessage = tr('register_error_passwords_dont_match');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.grey[300],
        title: Text(
          tr('register_error_title'),
          style: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).textTheme.bodyLarge
              : BblackTextStyle,
        ),
        content: Text(errorMessage,
            style: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).textTheme.bodyMedium
                : detailTextStyle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              overlayColor:
                  MaterialStateProperty.all<Color>(Colors.red.withOpacity(0.2)),
            ),
            child: Text('OK',
                style: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.bodyMedium
                    : MblackTextStyle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Icon(Icons.sunny, size: 100),
                Text(tr('register_create_account'),
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.headlineMedium
                        : BblackTextStyle),
                const SizedBox(
                  height: 20,
                ),
                EmailTextField(
                  controller: emailTextController,
                  hintText: tr('register_email_hint'),
                  obscureText: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: passwordTextController,
                  hintText: tr('register_password_hint'),
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: confirmTextController,
                  hintText: tr('register_confirm_password_hint'),
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyButton(
                  text: tr('register_sign_up'),
                  onTap: () => signUp(),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('register_already_have_account'),
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        tr('register_login_now'),
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
