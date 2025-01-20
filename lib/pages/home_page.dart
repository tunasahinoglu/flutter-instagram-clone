import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:provider/provider.dart';
import 'package:wall/components/wall_post.dart';
import 'package:wall/helper/helper_methods.dart';
import 'package:wall/pages/event_page.dart';
import 'package:wall/pages/profile_page.dart';
import 'package:wall/helper/image_helper.dart';
import 'package:path/path.dart' as path;
import 'package:wall/pages/user_list.dart';
import 'package:wall/services/chat_service.dart';
import 'package:wall/styles/text_styles.dart';
import 'package:wall/styles/themes/dark_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Locale _currentLocale = const Locale('en', 'US');

  final currentUser = FirebaseAuth.instance.currentUser!;
  final textController = TextEditingController();
  int _selectedIndex = 0;
  File? _image;

  late String imageUrl = '';

  final storage = FirebaseStorage.instance;
  bool isLoading = true;

  final List<String> _pageTitles = [
    'Wall',
    tr('bottom_nav_events'),
    tr('bottom_nav_profile')
  ];

  final PageController _pageController = PageController();

  int totalUnreadMessages = 0;

  @override
  void initState() {
    super.initState();
    getTotalUnreadMessages();
    getImageUrl();
  }

  Future<void> getTotalUnreadMessages() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final chatService = ChatService();
    int total = 0;

    QuerySnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();

    for (var doc in userSnapshot.docs) {
      String otherUserEmail = doc['email'];
      if (otherUserEmail != currentUserEmail) {
        QuerySnapshot<Map<String, dynamic>> snapshot = await chatService
            .getMessages(otherUserEmail, currentUserEmail)
            .first;

        for (var messageDoc in snapshot.docs) {
          if (messageDoc['receiverEmail'] == currentUserEmail &&
              messageDoc['isRead'] == false) {
            total++;
          }
        }
      }
    }

    setState(() {
      totalUnreadMessages = total;
    });
  }

  void postMessage() async {
    String? imageUrl;

    if (_image != null) {
      final uid = currentUser.email!;
      final fileName = path.basename(_image!.path);
      final destination = 'users/$uid/images/$fileName';
      imageUrl = await ImageHelper.uploadImage(_image!, destination);
    }

    if (textController.text.isNotEmpty || imageUrl != null) {
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
        'ImageUrl': imageUrl,
      });
    }

    FocusScope.of(context).unfocus();
    setState(() {
      textController.clear();
      _image = null;
    });
  }

  final ScrollController _scrollController = ScrollController();
  void onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImageHelper.pickImage();
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
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

  String getGreeting(BuildContext context, String name) {
    var timeOfDay = DateTime.now().hour;

    if (timeOfDay > 5 && timeOfDay < 12) {
      return "${tr('greeting_morning')}$name!";
    } else if (timeOfDay >= 12 && timeOfDay < 18) {
      return "${tr('greeting_afternoon')}$name!";
    } else {
      return "${tr('greeting_evening')}$name!";
    }
  }

  Future<void> getImageUrl() async {
    try {
      final ref = storage
          .ref('users/${currentUser.email}/profile_pictures/profile_photo.jpg');
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(_pageTitles[_selectedIndex],
              key: ValueKey<String>(_pageTitles[_selectedIndex]),
              style: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).textTheme.headlineLarge
                  : BblackTextStyle),
        ),
        actions: [
          IconButton(
            onPressed: () {
              themeProvider.toggleTheme();
            },
            icon: Icon(
              themeProvider.themeMode == ThemeMode.light
                  ? Icons.nightlight_round
                  : Icons.wb_sunny_rounded,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _currentLocale = value == 'tr'
                    ? const Locale('tr', 'TR')
                    : const Locale('en', 'US');
                EasyLocalization.of(context)!.setLocale(_currentLocale);

                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    });
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dialogBackgroundColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 30,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _currentLocale.languageCode == 'tr'
                              ? 'Türkçe'
                              : 'English',
                          style: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : MblackTextStyle,
                        ),
                      ),
                    );
                  },
                );
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'tr',
                child: Text(
                  'Türkçe',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.bodyMedium
                      : MblackTextStyle,
                ),
              ),
              PopupMenuItem<String>(
                value: 'en',
                child: Text(
                  'English',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).textTheme.bodyMedium
                      : MblackTextStyle,
                ),
              ),
            ],
            offset: const Offset(0, 50),
            child: Icon(
              Icons.language_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserList(),
                ),
              ).then((_) => getTotalUnreadMessages());
            },
            icon: Stack(
              children: <Widget>[
                Icon(
                  Icons.message_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                if (totalUnreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$totalUnreadMessages',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Montserrat'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all<Color>(
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
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
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: FutureBuilder<String?>(
                              future: getUsernameFromEmail(
                                  currentUser.email.toString()),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  String username = snapshot.data!;
                                  return Text(
                                    getGreeting(context, username),
                                    style: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(color: Colors.white)
                                        : BblackTextStyle,
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("User Posts")
                          .orderBy("TimeStamp", descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final post = snapshot.data!.docs[index];
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
                    ),
                  ],
                ),
              ),
            ],
          ),
          const EventPage(),
          ProfilePage(userEmail: currentUser.email.toString()),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Container(
                        height: 700,
                        padding: const EdgeInsets.all(15.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                tr("post_on_wall"),
                                style: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).textTheme.headlineMedium
                                    : BblackTextStyle,
                              ),
                              const SizedBox(height: 20),
                              _image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(30.0),
                                      child: Image.file(
                                        _image!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        tr("no_image_selected"),
                                        style: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                            : detailTextStyle,
                                      ),
                                    ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  await _pickImage();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(tr("pick_image"),
                                    style: MwhiteTextStyle),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: textController,
                                decoration: InputDecoration(
                                  hintText: tr("write_something"),
                                  hintStyle: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).textTheme.bodyMedium
                                      : MblackTextStyle,
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                ),
                                cursorColor: Colors.red,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      textController.clear();
                                      setState(() {
                                        _image = null;
                                      });
                                    },
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.black),
                                      overlayColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.red.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      tr("cancel"),
                                      style: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                          : BblackTextStyle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () {
                                      postMessage();
                                      Navigator.pop(context);
                                      setState(() {
                                        _image = null;
                                      });
                                    },
                                    style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.black),
                                      overlayColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.red.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      tr("post"),
                                      style: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                          : BblackTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Icon(
                Icons.add,
                color: Colors.black,
              ),
            )
          : _selectedIndex == 1
              ? FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25.0),
                        ),
                      ),
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Container(
                            height: 700,
                            padding: const EdgeInsets.all(15.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[500],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr("create_event"),
                                    style: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                        : BblackTextStyle,
                                  ),
                                  const SizedBox(height: 20),
                                  const CreateEventForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                  ),
                )
              : null,
      floatingActionButtonLocation:
          _selectedIndex == 0 ? FloatingActionButtonLocation.endFloat : null,
      bottomNavigationBar: Theme.of(context).brightness == Brightness.dark
          ? SnakeNavigationBar.color(
              backgroundColor: const Color(0xFF1E1E1E),
              behaviour: SnakeBarBehaviour.floating,
              snakeShape: SnakeShape.circle,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                side: BorderSide(color: Colors.grey.shade700, width: 1),
              ),
              elevation: 10,
              padding: const EdgeInsets.all(20),
              snakeViewColor: Colors.red,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              currentIndex: _selectedIndex,
              onTap: onTabTapped,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: tr('bottom_nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.event, color: Colors.white),
                  label: tr('bottom_nav_events'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: tr('bottom_nav_profile'),
                ),
              ],
            )
          : SnakeNavigationBar.color(
              backgroundColor: Colors.white,
              behaviour: SnakeBarBehaviour.floating,
              snakeShape: SnakeShape.circle,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              elevation: 10,
              padding: const EdgeInsets.all(20),
              snakeViewColor: Colors.red,
              selectedItemColor:
                  SnakeShape.circle == SnakeShape.indicator ? Colors.red : null,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              currentIndex: _selectedIndex,
              onTap: onTabTapped,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: tr('bottom_nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.event),
                  label: tr('bottom_nav_events'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: tr('bottom_nav_profile'),
                ),
              ],
            ),
    );
  }
}
