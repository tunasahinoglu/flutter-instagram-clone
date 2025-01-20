import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wall/styles/text_styles.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FocusNode? focusNode;
  const MyTextField(
      {super.key,
      required this.controller,
      required this.hintText,
      required this.obscureText,
      this.focusNode});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).textTheme.bodyMedium
          : MblackTextStyle,
      obscureText: obscureText,
      focusNode: focusNode,
      cursorColor: Colors.red,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(30),
        ),
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.normal,
          letterSpacing: 1.0,
          wordSpacing: 1.0,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FocusNode? focusNode;

  const EmailTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> emailDomains = [
      "hotmail.com",
      "gmail.com",
      "outlook.com",
      "yahoo.com"
    ];
    OverlayEntry? overlayEntry;
    String currentText = "";
    Timer? timer;
    final layerLink = LayerLink();

    void _removeOverlay() {
      overlayEntry?.remove();
      overlayEntry = null;
    }

    void _showOverlay(BuildContext context) {
      if (overlayEntry != null) {
        return;
      }

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: MediaQuery.of(context).size.width - 20,
          child: CompositedTransformFollower(
            link: layerLink,
            offset: const Offset(0.0, 50.0),
            child: Material(
              elevation: 4.0,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: emailDomains.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(currentText + "@" + emailDomains[index]),
                    onTap: () {
                      final atIndex = currentText.indexOf('@');
                      if (atIndex != -1) {
                        currentText = currentText.substring(0, atIndex);
                      }
                      controller.text = currentText + '@' + emailDomains[index];
                      controller.selection = TextSelection.collapsed(
                        offset: controller.text.length,
                      );
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry!);
    }

    void _onTextChanged(String value) {
      currentText = value;
      if (currentText.contains("@")) {
        _showOverlay(context);
        timer = Timer(const Duration(seconds: 3), _removeOverlay);
      } else {
        _removeOverlay();
        timer?.cancel();
      }
    }

    return CompositedTransformTarget(
        link: layerLink,
        child: TextField(
          controller: controller,
          style: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).textTheme.bodyMedium
              : MblackTextStyle,
          obscureText: obscureText,
          focusNode: focusNode,
          cursorColor: Colors.red,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(30),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(30),
            ),
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[
                    800] 
                : Colors
                    .white, 
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
              letterSpacing: 1.0,
              wordSpacing: 1.0,
              fontFamily: 'Montserrat',
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.alternate_email),
              color: Colors.red,
              onPressed: () {
                int cursorPosition = controller.selection.baseOffset;
                String textBeforeCursor =
                    controller.text.substring(0, cursorPosition);
                String textAfterCursor =
                    controller.text.substring(cursorPosition);
                controller.text = textBeforeCursor + '@' + textAfterCursor;
                controller.selection = TextSelection.collapsed(
                  offset: cursorPosition + 1,
                );
                _showOverlay(context);
              },
            ),
          ),
        ));
  }
}
