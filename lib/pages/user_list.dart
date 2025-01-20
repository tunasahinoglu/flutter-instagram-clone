import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:wall/pages/chat_page.dart';
import 'package:wall/pages/home_page.dart';
import 'package:wall/services/chat_service.dart';
import 'package:wall/styles/text_styles.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> userNamesAndEmails = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserNames();
  }

  Future<void> fetchUserNames() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Users').get();
      List<Map<String, dynamic>> users = [];

      for (final docSnapshot in snapshot.docs) {
        final data = docSnapshot.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('username') &&
            data.containsKey('email')) {
          final username = data['username'] as String;
          final email = data['email'] as String;
          if (email != currentUser.email) {
            final lastMessage = await getLastMessage(email);
            final unreadMessagesCount = await checkUnreadMessages(email);
            users.add({
              'username': username,
              'email': email,
              'userID': docSnapshot.id,
              'lastMessage': lastMessage,
              'timestamp': lastMessage != null
                  ? (await getLastMessageTimestamp(email))
                  : DateTime.fromMillisecondsSinceEpoch(0),
              'unreadMessagesCount': unreadMessagesCount,
            });
          }
        }
      }

      users.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        userNamesAndEmails = users;
        filteredUsers = users;
      });

      if (users.isEmpty) {
        print('No users found or no users except the current user.');
      }
    } catch (error) {
      print('Error fetching user names: $error');
    }
  }

  Future<int> checkUnreadMessages(String otherUserEmail) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final chatService = ChatService();

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await chatService.getMessages(otherUserEmail, currentUserEmail).first;

      int unreadCount = 0;
      for (var doc in snapshot.docs.reversed) {
        if (doc['receiverEmail'] == currentUserEmail &&
            doc['isRead'] == false) {
          unreadCount++;
        }
      }
      return unreadCount;
    } catch (e) {
      print('Error checking unread messages: $e');
      return 0;
    }
  }

  Future<String?> getLastMessage(String email) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final chatService = ChatService();

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await chatService.getMessages(email, currentUserEmail).first;

      if (snapshot.docs.isNotEmpty) {
        final lastMessageData = snapshot.docs.last.data();
        return lastMessageData['message'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting last message: $e');
      return null;
    }
  }

  Future<DateTime> getLastMessageTimestamp(String email) async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final chatService = ChatService();

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await chatService.getMessages(email, currentUserEmail).first;

      if (snapshot.docs.isNotEmpty) {
        final lastMessageData = snapshot.docs.last.data();
        return (lastMessageData['timestamp'] as Timestamp).toDate();
      } else {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    } catch (e) {
      print('Error getting last message timestamp: $e');
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<String> getImageUrl(String email) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('users/$email/profile_pictures/profile_photo.jpg');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting image URL: $e');
      return '';
    }
  }

  void filterUsers(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      filteredUsers = userNamesAndEmails
          .where(
              (user) => user['username'].toLowerCase().contains(lowerCaseQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !isSearching
            ? Text(
                context.tr('appTitle'),
                style: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.headlineMedium
                    : BblackTextStyle,
              )
            : TextField(
                controller: searchController,
                autofocus: true,
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  hintText: tr('search'),
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                style: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).textTheme.bodyMedium
                    : MblackTextStyle,
                onChanged: filterUsers,
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (isSearching) {
              setState(() {
                isSearching = false;
                searchController.clear();
                filteredUsers = userNamesAndEmails;
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            }
          },
          icon: Icon(
            isSearching ? Icons.close : Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredUsers = userNamesAndEmails;
                }
              });
            },
            icon: Icon(Icons.person_search_outlined,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final email = filteredUsers[index]['email'];

          return FutureBuilder<String>(
            future: getImageUrl(email),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else {
                final imageUrl = snapshot.data!;
                return Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                        child:
                            imageUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(
                        filteredUsers[index]['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        filteredUsers[index]['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((filteredUsers[index]['unreadMessagesCount'] ??
                                  0) >
                              0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${filteredUsers[index]['unreadMessagesCount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.send),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverEmail: filteredUsers[index]['email'],
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: Colors.grey[500],
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }
}
