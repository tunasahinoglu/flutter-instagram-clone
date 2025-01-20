import 'package:flutter/material.dart';
import 'package:wall/styles/text_styles.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  const MyButton({super.key, this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.red,
        ),
        child: Center(
          child: Text(
            text,
            style: 
            MwhiteTextStyle,
          ),
        ),
      ),
    );
  }
}
