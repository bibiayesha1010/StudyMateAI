import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chatmessage_model.dart';
import '../models/conversation_model.dart';

class FirestoreChatService {
  FirestoreChatService._();

  static final FirestoreChatService instance =
      FirestoreChatService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>>
      get _conversationCollection =>
          _firestore
              .collection("users")
              .doc(_uid)
              .collection("conversations");

  Future<void> createConversation(
      Conversation conversation) async {
    await _conversationCollection
        .doc(conversation.id)
        .set(conversation.toFirestore());
  }

  Future<void> saveMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    await _conversationCollection
        .doc(conversationId)
        .collection("messages")
        .add(message.toFirestore());

    await _conversationCollection
        .doc(conversationId)
        .update({
      "updatedAt": Timestamp.now(),
    });
  }

  Future<List<Conversation>> loadConversations() async {
    final snapshot = await _conversationCollection
        .orderBy("updatedAt", descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => Conversation.fromFirestore(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<ChatMessage>> loadMessages(
      String conversationId) async {
    final snapshot = await _conversationCollection
        .doc(conversationId)
        .collection("messages")
        .orderBy("timestamp")
        .get();

    return snapshot.docs
        .map(
          (doc) => ChatMessage.fromFirestore(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<void> deleteConversation(
      String conversationId) async {
    await _conversationCollection
        .doc(conversationId)
        .delete();
  }

  Future<void> renameConversation(
    String conversationId,
    String title,
  ) async {
    await _conversationCollection
        .doc(conversationId)
        .update({
      "title": title,
    });
  }

 
}