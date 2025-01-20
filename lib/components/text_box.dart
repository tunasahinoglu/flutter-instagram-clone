import 'package:flutter/material.dart';
import 'package:wall/styles/text_styles.dart';

class MyTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;
  final bool isCurrentUser;

  const MyTextBox(
      {super.key,
      required this.text,
      required this.sectionName,
      required this.onPressed,
      required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.only(left: 15, bottom: 15, top: 15),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sectionName,
                  style: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.bodyMedium
                      : MblackTextStyle),
              if (isCurrentUser)
                IconButton(
                    onPressed: onPressed, icon: const Icon(Icons.settings)),
            ],
          ),
          Text(text,
              style: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).textTheme.bodyMedium
                  : detailTextStyle)
        ],
      ),
    );
  }
}
