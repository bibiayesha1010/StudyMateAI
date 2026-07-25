import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatmessage_model.dart';

class Conversation {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Conversation(
      id: id,
      title: data['title'] ?? "New Chat",
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      messages: [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
  
    };
  }
}