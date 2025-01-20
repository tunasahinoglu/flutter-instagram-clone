import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wall/components/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> sendMessage(String receiverEmail, String message) async {
    final String currentUserEmail = currentUser.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderEmail: currentUserEmail,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
      isRead: false, 
    );

    List<String> emails = [currentUserEmail, receiverEmail];
    emails.sort();
    String chatRoomID = emails.join('_');

    await _firestore
        .collection("Chat Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    await _firestore 
        .collection("Chat Rooms")
        .doc(chatRoomID)
        .collection("last_message")
        .doc('message')
        .delete();

    await _firestore
        .collection("Chat Rooms")
        .doc(chatRoomID)
        .collection("last_message")
        .doc('message')
        .set(newMessage.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String userEmail, String otherUserEmail) {
    List<String> emails = [userEmail, otherUserEmail];
    emails.sort();
    String chatRoomID = emails.join('_');

    return _firestore
        .collection("Chat Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String otherUserEmail) async {
    final String currentUserEmail = currentUser.email!;
    List<String> emails = [currentUserEmail, otherUserEmail];
    emails.sort();
    String chatRoomID = emails.join('_');

    QuerySnapshot unreadMessages = await _firestore
        .collection("Chat Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverEmail', isEqualTo: currentUserEmail)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();

    for (QueryDocumentSnapshot doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}