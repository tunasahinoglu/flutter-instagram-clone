import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wall/components/comment_button.dart';
import 'package:wall/components/comments.dart';
import 'package:wall/components/text_field.dart';
import 'package:wall/components/wall_post.dart';
import 'package:wall/helper/helper_methods.dart';
import 'package:wall/pages/profile_page.dart';
import 'package:wall/styles/text_styles.dart';
import 'dart:async';

class EventPost extends StatefulWidget {
  final String eventId;
  final String user;
  final String eventName;
  final String? message;
  final DateTime eventTime;
  final List<String> attendees;
  final String? imageUrl;

  const EventPost(
      {Key? key,
      required this.eventId,
      required this.user,
      required this.eventName,
      this.message,
      required this.eventTime,
      required this.attendees,
      this.imageUrl})
      : super(key: key);

  @override
  _EventPostState createState() => _EventPostState();
}

class _EventPostState extends State<EventPost> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isAttending = false;
  late String username = '';
  Timer? _timer;
  late String remainingTime = '';

  late String imageUrl = "";
  final storage = FirebaseStorage.instance;
  bool isLoading = true;

  final _commentTextController = TextEditingController();

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    getImageUrl();
    isAttending = widget.attendees.contains(currentUser.email);
    getUsernameFromEmail(widget.user).then((fetchedUsername) {
      if (fetchedUsername != null) {
        setState(() {
          username = fetchedUsername;
        });
      }
    });
    remainingTime = formatEventTime(widget.eventTime);
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  Future<String?> getImageUrlwithEmail(String email) async {
    try {
      final ref =
          storage.ref('users/$email/profile_pictures/profile_photo.jpg');
      final url = await ref.getDownloadURL();
      return url; 
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = formatEventTime(widget.eventTime);
      });
    });
  }

  void toggleAttendance() {
    setState(() {
      isAttending = !isAttending;
    });

    DocumentReference eventRef =
        FirebaseFirestore.instance.collection('Events').doc(widget.eventId);

    if (isAttending) {
      eventRef.update({
        'Attendees': FieldValue.arrayUnion([currentUser.email])
      });
    } else {
      eventRef.update({
        'Attendees': FieldValue.arrayRemove([currentUser.email])
      });
    }
  }

  String formatEventTime(DateTime eventTime) {
    Duration difference = eventTime.difference(DateTime.now());
    if (difference.isNegative) {
      return tr("event_has_ended");
    } else if (difference.inDays == 0 &&
        difference.inHours == 0 &&
        difference.inMinutes == 0) {
      return "${difference.inSeconds} ${tr("seconds")}";
    } else if (difference.inDays == 0 && difference.inHours == 0) {
      return "${difference.inMinutes % 60} ${tr("minutes")}";
    } else if (difference.inDays < 1) {
      return "${difference.inHours % 24} ${tr("hours")} ${difference.inMinutes % 60} ${tr("minutes")}";
    } else {
      return "${difference.inDays} ${tr("days")} ${difference.inHours % 24} ${tr("hours")} ${difference.inMinutes % 60} ${tr("minutes")}";
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

  String dayEventTime(DateTime eventTime) {
    String locale = EasyLocalization.of(context)!.locale.toString();

    String formattedTime =
        DateFormat('dd.MM.yyyy HH:mm', locale).format(eventTime);

    String dayOfWeekEnglish =
        DateFormat('EEEE', locale).format(eventTime).toLowerCase();

    String dayOfWeek = tr('daysOfWeek.$dayOfWeekEnglish');

    Map<String, String> daysOfWeekMap = {
      'daysOfWeek.pazartesi': 'Pazartesi',
      'daysOfWeek.salı': 'Salı',
      'daysOfWeek.çarşamba': 'Çarşamba',
      'daysOfWeek.perşembe': 'Perşembe',
      'daysOfWeek.cuma': 'Cuma',
      'daysOfWeek.cumartesi': 'Cumartesi',
      'daysOfWeek.pazar': 'Pazar',
    };

    dayOfWeek = daysOfWeekMap[dayOfWeek] ?? dayOfWeek;

    return "$dayOfWeek $formattedTime";
  }

  void addComment(String commentText) {
    FirebaseFirestore.instance
        .collection("Events")
        .doc(widget.eventId)
        .collection("Comments")
        .add({
      "CommentText": commentText,
      "CommentedBy": currentUser.email,
      "CommentTime": Timestamp.now()
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                  child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 15),
                Text(username,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).textTheme.bodyMedium
                        : MblackTextStyle),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.user == currentUser.email)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            FirebaseFirestore.instance
                                .collection("Events")
                                .doc(widget.eventId)
                                .delete()
                                .then((value) => Navigator.of(context).pop());
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
              ],
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 20),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  child: Text(widget.eventName,
                      style: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).textTheme.bodyLarge
                          : BblackTextStyle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 20),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  child: widget.message != null
                      ? Text("${widget.message}",
                          style: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : MblackTextStyle)
                      : Text("", style: MblackTextStyle),
                ),
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).dividerColor
                : Colors.grey[700],
            height: 20,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 10),
          Center(
              child: Text(
            dayEventTime(widget.eventTime),
            style: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).textTheme.bodyMedium
                : MblackTextStyle,
          )),
          if (widget.imageUrl != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(
                          imageUrl: widget.imageUrl!,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'image_${widget.eventId}',
                    child: Container(
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
                          width: 250,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  remainingTime,
                  style: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.bodyMedium
                      : MblackTextStyle,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      !isAttending
                          ? await _audioPlayer
                              .play(AssetSource('sounds/attend.mp3'))
                          : null;
                      toggleAttendance();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: isAttending ? Colors.red : Colors.green,
                      ),
                      child: Center(
                        child: Text(
                          isAttending
                              ? tr("cancel_attendance")
                              : tr("join_event"),
                          style: MwhiteTextStyle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
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
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 5,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  tr("_attendees"),
                                  style: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                      : BblackTextStyle,
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: widget.attendees.length,
                                    itemBuilder: (context, index) {
                                      return FutureBuilder<String?>(
                                        future: getImageUrlwithEmail(
                                            widget.attendees[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                              color: Colors.red,
                                            ));
                                          }
                                          if (snapshot.hasError) {
                                            return const ListTile(
                                              leading: CircleAvatar(
                                                  child: Icon(Icons.error)),
                                              title:
                                                  Text('Error loading image'),
                                            );
                                          }
                                          String? imageUrl = snapshot.data;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: imageUrl !=
                                                              null &&
                                                          imageUrl.isNotEmpty
                                                      ? NetworkImage(imageUrl)
                                                      : null,
                                                  child: imageUrl == null ||
                                                          imageUrl.isEmpty
                                                      ? const Icon(Icons.person)
                                                      : null,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: FutureBuilder<String?>(
                                                    future:
                                                        getUsernameFromEmail(
                                                            widget.attendees[
                                                                index]),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                          color: Colors.red,
                                                        ));
                                                      }
                                                      if (snapshot.hasError ||
                                                          !snapshot.hasData) {
                                                        return const Text(
                                                            'Error loading username');
                                                      }
                                                      String username =
                                                          snapshot.data!;
                                                      return Text(
                                                        username,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Montserrat',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      "${widget.attendees.length} ${tr("attendees")}",
                      style: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).textTheme.bodyMedium
                          : MblackTextStyle,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
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
                                              .collection("Events")
                                              .doc(widget.eventId)
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
                            .collection("Events")
                            .doc(widget.eventId)
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
              )
            ],
          ),
        ],
      ),
    );
  }
}
