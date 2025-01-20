import 'package:flutter/material.dart';
import 'package:wall/pages/login_page.dart';
import 'package:wall/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = false;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: showLoginPage ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        child: showLoginPage
            ? LoginPage(
                key: const ValueKey('LoginPage'),
                onTap: togglePages,
              )
            : RegisterPage(
                key: const ValueKey('RegisterPage'),
                onTap: togglePages,
              ),
      ),
    );
  }
}
