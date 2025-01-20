import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wall/components/button.dart';
import 'package:wall/components/event.dart';
import 'package:wall/styles/text_styles.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
        
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Events')
                .where('EventTime', isGreaterThan: Timestamp.now())
                .orderBy('EventTime', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  ),
                );
              }

              return SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      var event = snapshot.data!.docs[index];
      var attendees = event['Attendees'] ?? [];
      String? imageUrl = event['ImageUrl'] as String?;
      String creatorEmail = event['CreatorEmail'];

      return EventPost(
        eventId: event.id,
        user: creatorEmail,
        eventName: event['EventName'],
        message: event['EventMessage'],
        eventTime: event['EventTime'].toDate(),
        attendees: List<String>.from(attendees),
        imageUrl: imageUrl,
      );
    },
    childCount: snapshot.data!.docs.length,
  ),
);

            },
          ),
            SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20,),
                Padding(
                  padding: const EdgeInsets.only(left: 60, right: 60, bottom: 100),
                  child: MyButton(
                    text: tr("see_past_events"),
                    onTap: () {
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
                                      margin: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[500],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(tr("past_events"), style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.bold, fontSize: 24),),
                                    const SizedBox(height: 20),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('Events')
                                          .where('EventTime', isLessThan: Timestamp.now())
                                          .orderBy('EventTime', descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.red,
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            var event = snapshot.data!.docs[index];
                                            var attendees = event['Attendees'] ?? [];
                                            String? imageUrl = event['ImageUrl'] as String?;
                                            String creatorEmail = event['CreatorEmail'];

                                            return EventPost(
                                              eventId: event.id,
                                              user: creatorEmail, 
                                              eventName: event['EventName'],
                                              message: event['EventMessage'],
                                              eventTime: event['EventTime'].toDate(),
                                              attendees: List<String>.from(attendees),
                                              imageUrl: imageUrl,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateEventForm extends StatefulWidget {
  const CreateEventForm({super.key});

  @override
  _CreateEventFormState createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventMessageController = TextEditingController();
  DateTime? _eventTime;
  File? _image; 

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImage(String eventId) async {
    try {
      if (_image == null) {
        await FirebaseFirestore.instance
            .collection('Events')
            .doc(eventId)
            .update({
          'ImageUrl': null,
        });
        return;
      }

      var storageRef =
          FirebaseStorage.instance.ref().child('events/$eventId.png');
      await storageRef.putFile(_image!);

      String imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Events')
          .doc(eventId)
          .update({
        'ImageUrl': imageUrl,
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final ThemeData themeData = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(primary: Colors.red),
      buttonTheme: const ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: themeData,
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: themeData,
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _eventTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            cursorColor: Colors.red,
            controller: _eventNameController,
            decoration: InputDecoration(
              labelText: tr("event_name"),
              labelStyle: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : detailTextStyle,
              focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.red), 
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr("please_enter_event_name");
              }
              return null;
            },
          ),
          const SizedBox(height: 15,),
          TextFormField(
            cursorColor: Colors.red,
            controller: _eventMessageController,
            decoration: InputDecoration(
              labelText: tr("event_message"),
              labelStyle: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : detailTextStyle,
              focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.red), 
              ),
            ),
            
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              _selectDateTime(context); 
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: _eventTime == null ? Colors.red : Colors.red[900],
              ),
              child: Center(
                child: Text(
                    _eventTime == null
                        ? tr("pick_event_time")
                        : tr("event_time_selected"),
                    style: MwhiteTextStyle),
              ),
            ),
          ),
    
          _eventTime != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${tr(DateFormat('EEEE', 'tr_TR').format(_eventTime!))} ${DateFormat('dd.MM.yyyy HH:mm').format(_eventTime!)}',
              style: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
                              : detailTextStyle, 
            ),
          )
        : const SizedBox.shrink(),
    
          const SizedBox(height: 30),
          _image != null
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(30.0), 
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover, 
                  ),
                )
              : Center(
                  child: Text(
                    tr("no_image_selected"),
                    style: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).textTheme.bodyMedium
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
            child: Text(tr("pick_image"), style: MwhiteTextStyle),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
  if (_formKey.currentState!.validate() && _eventTime != null) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;

    DocumentReference eventRef = await FirebaseFirestore.instance.collection('Events').add({
      'EventName': _eventNameController.text,
      'EventMessage': _eventMessageController.text,
      'EventTime': _eventTime,
      'Attendees': [], 
      'CreatorEmail': currentUserEmail, 
    });

    await _uploadImage(eventRef.id);

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(tr("fill_event_time")),
        duration: const Duration(seconds: 2),
      ),
    );
  }
},

            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 10),
                Text(
                 tr("create_event"),
                  style: MwhiteTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventMessageController.dispose();
    super.dispose();
  }
}
