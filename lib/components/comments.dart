import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wall/styles/text_styles.dart';

class Comment extends StatefulWidget {
  final String text;
  final String user;
  final String time;

  const Comment(
      {super.key, required this.text, required this.user, required this.time});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  late String imageUrl = "";
  final storage = FirebaseStorage.instance;
  bool isLoading = true;

  late String username = '';

  @override
  void initState() {
    super.initState();
    getImageUrl();

    getUsername();
  }

  Future<void> getUsername() async {
    String? fetchedUsername = await getUsernameFromEmail(widget.user);
    if (fetchedUsername != null) {
      setState(() {
        username = fetchedUsername;
      });
    }
  }

  Future<String?> getUsernameFromEmail(String email) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      QuerySnapshot querySnapshot = await firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String username = querySnapshot.docs.first['username'];
        return username;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> getImageUrl() async {
    try {
      final ref = storage
          .ref('users/${widget.user}/profile_pictures/profile_photo.jpg');
      final url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.grey[300], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Text(username, style:  Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).textTheme.bodyMedium
      : MblackTextStyle),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 52.0),
            child: Text(widget.text, style:  Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).textTheme.bodyMedium
      : MblackTextStyle),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              widget.time,
              style:  Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).textTheme.bodySmall
      : detailTextStyle,
            ),
          )
        ],
      ),
    );
  }
}
