import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wall/components/message.dart';
import 'package:wall/components/text_field.dart';
import 'package:wall/helper/helper_methods.dart';
import 'package:wall/pages/user_list.dart';
import 'package:wall/services/chat_service.dart';
import 'package:wall/styles/text_styles.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String receiverEmail;

  ChatPage({required this.receiverEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FocusNode myFocusNode = FocusNode();

  String? receiverUsername;

  @override
  void initState() {
    super.initState();

    getImageUrl();

    _chatService.markMessagesAsRead(widget.receiverEmail);

    getUsernameFromEmail(widget.receiverEmail).then((username) {
      setState(() {
        receiverUsername = username;
      });
    });

    myFocusNode.addListener(() {
      if (!myFocusNode.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 100),
          () => scrollDown(),
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () => scrollDown());
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();

  void scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
  }

  Future<void> sendMessage(String receiverEmail, String message) async {
    final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderEmail: currentUserEmail,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
      isRead: false,
    );

    List<String> ids = [currentUserEmail, receiverEmail];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    String? senderUsername = await getUsernameFromEmail(currentUserEmail);
    if (senderUsername != null) {
      await sendNotification(receiverEmail, senderUsername, message);
    }
  }

 Future<void> sendNotification(String receiverEmail, String senderName, String message) async {
  DocumentSnapshot receiverSnapshot = await _firestore.collection('Users').doc(receiverEmail).get();
  String? deviceToken = receiverSnapshot.get('deviceToken');

  if (deviceToken != null) {
    Map<String, dynamic> notificationPayload = {
      'to': deviceToken,
      'notification': {
        'title': senderName,
        'body': message,
        'sound': 'default',
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'message': message,
      },
    };

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY', 
      },
      body: json.encode(notificationPayload),
    );
  }
}


  Future<String?> getFCMToken(String receiverEmail) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(receiverEmail)
          .get();
      return doc['fcmToken'];
    } catch (e) {
      print('FCM token alınamadı: $e');
      return null;
    }
  }

  void markMessagesAsRead() async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    List<String> ids = [currentUserEmail, widget.receiverEmail];
    ids.sort();
    String chatRoomId = ids.join("_");

    QuerySnapshot unreadMessages = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: currentUserEmail)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (QueryDocumentSnapshot doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
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

  late String imageUrl = "";
  final storage = FirebaseStorage.instance;
  bool isLoading = true;

  Future<void> getImageUrl() async {
    try {
      final ref = storage.ref(
          'users/${widget.receiverEmail}/profile_pictures/profile_photo.jpg');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverUsername ?? '',
            style: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).textTheme.headlineMedium
                : BblackTextStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserList(),
                ));
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderEmail = currentUser.email!;
    DateTime? previousDate;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessages(widget.receiverEmail, senderEmail),
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.red,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(tr("no_messages_yet"), style: detailTextStyle));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final messageData = snapshot.data!.docs[index].data();
            final isMe = messageData['senderEmail'] == senderEmail;
            final isRead = messageData['isRead'];
            final messageTimestamp =
                (messageData['timestamp'] as Timestamp).toDate();
            final currentMessageDate = DateTime(
              messageTimestamp.year,
              messageTimestamp.month,
              messageTimestamp.day,
            );

            Widget dateHeader = const SizedBox.shrink();

            if (previousDate == null ||
                previousDate!.difference(currentMessageDate).inDays != 0) {
              dateHeader = Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      formatDate(currentMessageDate),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              );
              previousDate = currentMessageDate;
            }

            return Column(
              children: [
                dateHeader,
                ListTile(
                  trailing: !isMe && !isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  title: Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: imageUrl.isEmpty
                                      ? null
                                      : NetworkImage(imageUrl),
                                  child: imageUrl.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              const SizedBox(width: 8.0),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        messageData['message'],
                                        style: detailTextStyle,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          formatTime(messageData['timestamp']),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.grey[700],
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today)) {
      return tr("today");
    } else if (date.isAtSameMomentAs(yesterday)) {
      return tr("yesterday");
    } else {
      int month = date.month;
      String monthName = tr("months.$month");
      return "${date.day} $monthName ${date.year}";
    }
  }

  Widget _buildUserInput() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.fastOutSlowIn,
                  );
                });
              },
              child: MyTextField(
                controller: _messageController,
                hintText: tr('type_a_message'),
                obscureText: false,
                focusNode: myFocusNode,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (_messageController.text.isNotEmpty) {
              _chatService.sendMessage(
                widget.receiverEmail,
                _messageController.text,
              );
              _messageController.clear();
            }
          },
          icon: const Icon(Icons.keyboard_arrow_up_sharp),
        ),
      ],
    );
  }
}
