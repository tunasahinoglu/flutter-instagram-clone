import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wall/components/button.dart';
import 'package:wall/components/text_field.dart';
import 'package:wall/pages/home_page.dart';
import 'package:wall/styles/text_styles.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  void signIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = tr('login_error_title');
      if (e.code == 'user-not-found') {
        errorMessage = tr('login_error_user_not_found');
      } else if (e.code == 'wrong-password') {
        errorMessage = tr('login_error_wrong_password');
      } else if (e.code == 'invalid-email') {
        errorMessage = tr('login_error_invalid_email');
      }

      displayMessage(context, errorMessage);
    }
  }

  void displayMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          tr('login_error_title'),
          style: BblackTextStyle,
        ),
        content: Text(message, style: detailTextStyle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              overlayColor:
                  MaterialStateProperty.all<Color>(Colors.red.withOpacity(0.2)),
            ),
            child: Text('OK', style: MblackTextStyle),
          )
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
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Icon(Icons.wb_sunny, size: 100),
                Text(tr('login_welcome_back'),
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.headlineMedium
                        : BblackTextStyle),
                const SizedBox(
                  height: 20,
                ),
                EmailTextField(
                  controller: emailTextController,
                  hintText: tr('login_email_hint'),
                  obscureText: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: passwordTextController,
                  hintText: tr('login_password_hint'),
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyButton(
                  text: tr('login_sign_in'),
                  onTap: () => signIn(context),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('login_not_member'),
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
                        tr('login_register_now'),
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
