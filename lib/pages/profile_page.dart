import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wall/auth/login_or_register.dart';
import 'package:wall/components/text_box.dart';
import 'package:wall/components/wall_post.dart';
import 'package:wall/helper/helper_methods.dart';
import 'package:wall/helper/image_helper.dart';
import 'package:wall/pages/chat_page.dart';
import 'package:wall/styles/text_styles.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;

  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");
  File? _image;

  Future<void> _pickImage() async {
    if (widget.userEmail != currentUser.email) return;

    final pickedImage = await ImageHelper.pickImage();
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    final destination =
        'users/${widget.userEmail}/profile_pictures/profile_photo.jpg';
    final imageUrl = await ImageHelper.uploadImage(_image!, destination);
    if (imageUrl != null) {
      await usersCollection
          .doc(widget.userEmail)
          .update({'profile_picture': imageUrl});
    }
  }

  Future<void> editField(String field) async {
    if (widget.userEmail != currentUser.email) return;

    String newValue = "";
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Colors.white,
              title: Text(
                tr("edit"),
                style: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.bodyMedium
                    : MblackTextStyle,
              ),
              content: TextField(
                autofocus: true,
                style: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.bodyMedium
                    : detailTextStyle,
                decoration: InputDecoration(
                    hintText: tr("edit_info"),
                    hintStyle: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : detailTextStyle,
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red))),
                cursorColor: Colors.red,
                onChanged: (value) {
                  newValue = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                    overlayColor: MaterialStateProperty.all<Color>(
                        Colors.red.withOpacity(0.2)),
                  ),
                  child: Text(
                    tr("cancel"),
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : MblackTextStyle,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(newValue),
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                    overlayColor: MaterialStateProperty.all<Color>(
                        Colors.red.withOpacity(0.2)),
                  ),
                  child: Text(
                    tr("save"),
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : MblackTextStyle,
                  ),
                )
              ],
            ));

    if (newValue.trim().isNotEmpty) {
      await usersCollection.doc(widget.userEmail).update({field: newValue});
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginOrRegister(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("Users")
                .doc(widget.userEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                bool isCurrentUser = widget.userEmail == currentUser.email;
                return ListView(
                  children: [
                    GestureDetector(
                      onTap: isCurrentUser ? _pickImage : null,
                      child: Builder(
                        builder: (context) {
                          double screenWidth =
                              MediaQuery.of(context).size.width;

                          return Container(
                            width: screenWidth * 0.5,
                            height: screenWidth * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              image: userData['profile_picture'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          userData['profile_picture']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: userData['profile_picture'] == null
                                  ? Colors.red
                                  : null,
                            ),
                            child: userData['profile_picture'] == null
                                ? const Icon(Icons.account_circle, size: 50)
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25, top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userData['username'],
                            textAlign: TextAlign.start,
                            style:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).textTheme.headlineMedium
                                    : BblackTextStyle,
                          ),
                          if (isCurrentUser)
                            IconButton(
                                onPressed: signOut,
                                icon: const Icon(Icons.logout)),
                          if (!isCurrentUser)
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                        receiverEmail: widget.userEmail),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Text(
                        tr("details"),
                        style: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).textTheme.bodyMedium
                            : MblackTextStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, top: 15),
                      child: Text(widget.userEmail,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : detailTextStyle),
                    ),
                    MyTextBox(
                      text: userData['username'],
                      sectionName: tr("username"),
                      onPressed:
                          isCurrentUser ? () => editField('username') : null,
                      isCurrentUser: isCurrentUser,
                    ),
                    MyTextBox(
                      text: userData['bio'],
                      sectionName: tr("bio"),
                      onPressed: isCurrentUser ? () => editField('bio') : null,
                      isCurrentUser: isCurrentUser,
                    ),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("User Posts")
                          .orderBy("TimeStamp", descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var userPosts = snapshot.data!.docs.where((post) {
                            return post['UserEmail'] == widget.userEmail;
                          }).toList();

                          return ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userPosts.length,
                            itemBuilder: (context, index) {
                              var post = userPosts[index];
                              return WallPost(
                                message: post['Message'],
                                user: post['UserEmail'],
                                postId: post.id,
                                likes: List<String>.from(post['Likes'] ?? []),
                                time: formatDate(post['TimeStamp']),
                                imageUrl: post.data().containsKey('ImageUrl')
                                    ? post['ImageUrl']
                                    : null,
                                timestamp: post['TimeStamp'],
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style: MblackTextStyle,
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        );
                      },
                    )
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error${snapshot.error}'),
                );
              }
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.red,
                ),
              );
            }));
  }
}
