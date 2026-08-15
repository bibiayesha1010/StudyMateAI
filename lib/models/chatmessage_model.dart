import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  final String? fileName; // e.g. "notes.pdf" — shown as a chip in the bubble

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.fileName,
  });

  factory ChatMessage.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return ChatMessage(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imagePath: data['imagePath'],
      fileName: data['fileName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'imagePath': imagePath,
      'fileName': fileName,
    };
  }
}