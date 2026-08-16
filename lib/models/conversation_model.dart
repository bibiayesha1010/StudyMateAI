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

  factory Conversation.fromJson(
    Map<String, dynamic> data,
  ) {
    return Conversation(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'New Chat',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      messages: ((data['messages'] as List?) ?? const [])
          .map((message) => ChatMessage.fromJson(Map<String, dynamic>.from(message)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}