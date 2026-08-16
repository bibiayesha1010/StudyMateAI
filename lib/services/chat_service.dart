import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_model.dart';
import '../models/chatmessage_model.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  static const String _storageKey = 'study_mate_chat_history';

  final List<Conversation> _conversations = [];
  SharedPreferences? _prefs;

  List<Conversation> get conversations => _conversations;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await loadPersistedConversations();
  }

  Future<void> loadPersistedConversations() async {
    _prefs ??= await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }

      final conversations = (decoded['conversations'] as List? ?? const [])
          .map((conversation) => Conversation.fromJson(Map<String, dynamic>.from(conversation)))
          .toList();

      _conversations
        ..clear()
        ..addAll(conversations);
    } catch (_) {
      _conversations.clear();
    }
  }

  Future<void> persistConversations() async {
    _prefs ??= await SharedPreferences.getInstance();

    final data = {
      'conversations': _conversations.map((conversation) => conversation.toJson()).toList(),
    };

    await _prefs!.setString(_storageKey, jsonEncode(data));
  }

  Conversation createConversation(String firstMessage) {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: firstMessage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [
        ChatMessage(
          text: firstMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ],
    );

    _conversations.insert(0, conversation);
    return conversation;
  }

  void addMessage(
    Conversation conversation,
    ChatMessage message,
  ) {
    conversation.messages.add(message);
    conversation.updatedAt = DateTime.now();
  }

  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere(
      (conversation) => conversation.id == id,
    );
    await persistConversations();
  }

  Future<void> renameConversation(
    String id,
    String newTitle,
  ) async {
    final conversation = _conversations.firstWhere(
      (conversation) => conversation.id == id,
    );

    conversation.title = newTitle;
    await persistConversations();
  }

  Future<void> deleteAllConversations() async {
    _conversations.clear();
    await persistConversations();
  }
}