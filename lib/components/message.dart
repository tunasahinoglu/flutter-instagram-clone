import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final Timestamp timestamp;
  final bool isRead;

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
