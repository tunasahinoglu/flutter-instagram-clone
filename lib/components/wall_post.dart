import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wall/components/comment_button.dart';
import 'package:wall/components/comments.dart';
import 'package:wall/components/like_button.dart';
import 'package:wall/components/text_field.dart';
import 'package:wall/helper/helper_methods.dart';
import 'package:wall/pages/profile_page.dart';
import 'package:wall/styles/text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String postId;
  final List<String> likes;
  final String time;
  final String? imageUrl;
  final Timestamp? timestamp;

  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
    required this.time,
    this.imageUrl,
    this.timestamp,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  final _commentTextController = TextEditingController();

  late String imageUrl;
  final storage = FirebaseStorage.instance;

  bool isLoading = true;

  late String username = '';

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);

    imageUrl = '';
    getImageUrl();

    getUsername();
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

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('User Posts').doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email])
      });
    } else {
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email])
      });
    }
  }

  void addComment(String commentText) {
    FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.postId)
        .collection("Comments")
        .add({
      "CommentText": commentText,
      "CommentedBy": currentUser.email,
      "CommentTime": Timestamp.now()
    });

    FocusScope.of(context).unfocus();
  }

  void showCommentDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(tr("add_comment")),
              content: TextField(
                controller: _commentTextController,
                decoration: InputDecoration(hintText: tr("write_comment")),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _commentTextController.clear();
                    },
                    child: Text(tr("cancel"))),
                TextButton(
                    onPressed: () {
                      addComment(_commentTextController.text);
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                      _commentTextController.clear();
                    },
                    child: Text(tr("post"))),
              ],
            ));
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

  Future<void> deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection('User Posts')
          .doc(widget.postId)
          .delete();

      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        final ref = storage.refFromURL(widget.imageUrl!);
        await ref.delete();
      }
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime postDateTime = widget.timestamp?.toDate() ?? DateTime.now();
    Locale locale = Localizations.localeOf(context);
    String timeAgo = timeago.format(postDateTime, locale: locale.languageCode);

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      userEmail: widget.user,
                                    ),
                                  ),
                                );
                              },
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: imageUrl.isEmpty
                                      ? null
                                      : NetworkImage(imageUrl),
                                  child: imageUrl.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(username,
                                    style: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context).textTheme.bodyMedium
                                        : MblackTextStyle)
                              ])),
                          const SizedBox(
                            width: 10,
                          ),
                          if (widget.user == currentUser.email)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  deletePost();
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text(
                                      tr('delete_post'),
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ];
                              },
                              icon: const Icon(Icons.more_vert),
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (widget.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImage(
                                      imageUrl: widget.imageUrl!),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'image_${widget.postId}',
                              child: Container(
                                width: MediaQuery.of(context).size.width - 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      spreadRadius: 4,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    widget.imageUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 20),
                        child: Row(
                          children: [
                            SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Text(widget.message,
                                    style: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context).textTheme.bodyMedium
                                        : MblackTextStyle)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      )
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      LikeButton(isLiked: isLiked, onTap: toggleLike),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        widget.likes.length.toString(),
                        style: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).textTheme.bodyMedium
                            : MblackTextStyle,
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  Column(
                    children: [
                      CommentButton(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(25.0),
                              ),
                            ),
                            builder: (BuildContext context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: Container(
                                  height: 400,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[500],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Expanded(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection("User Posts")
                                              .doc(widget.postId)
                                              .collection("Comments")
                                              .orderBy("CommentTime",
                                                  descending: true)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.red,
                                                ),
                                              );
                                            }

                                            return ListView(
                                              shrinkWrap: true,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              children: snapshot.data!.docs
                                                  .map((doc) {
                                                final commentData = doc.data()
                                                    as Map<String, dynamic>;
                                                return Comment(
                                                  text: commentData[
                                                      "CommentText"],
                                                  user: commentData[
                                                      "CommentedBy"],
                                                  time: formatDate(commentData[
                                                      "CommentTime"]),
                                                );
                                              }).toList(),
                                            );
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: MyTextField(
                                                controller:
                                                    _commentTextController,
                                                hintText: tr("write_comment"),
                                                obscureText: false,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.send),
                                              onPressed: () {
                                                addComment(
                                                    _commentTextController
                                                        .text);
                                                FocusScope.of(context)
                                                    .unfocus();
                                                _commentTextController.clear();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("User Posts")
                            .doc(widget.postId)
                            .collection("Comments")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text("0",
                                style: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : MblackTextStyle);
                          }
                          return Text(
                            snapshot.data!.docs.length.toString(),
                            style:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : MblackTextStyle,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeAgo,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : detailTextStyle,
                  ),
                  Text(
                    widget.time,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : detailTextStyle,
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  void _closePage(BuildContext context) {
    Navigator.of(context).pop(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Container(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          _closePage(context);
        },
        onVerticalDragEnd: (details) {
          _closePage(context);
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Hero(
              tag: imageUrl,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
