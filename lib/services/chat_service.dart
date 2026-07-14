import '../models/conversation_model.dart';
import '../models/chatmessage_model.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;

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

  void deleteConversation(String id) {
    _conversations.removeWhere(
      (conversation) => conversation.id == id,
    );
  }

  void toggleFavorite(String id) {
    final conversation = _conversations.firstWhere(
      (conversation) => conversation.id == id,
    );

    conversation.isFavorite = !conversation.isFavorite;
  }

  void renameConversation(
    String id,
    String newTitle,
  ) {
    final conversation = _conversations.firstWhere(
      (conversation) => conversation.id == id,
    );

    conversation.title = newTitle;
  }

  void deleteAllConversations() {
    _conversations.clear();
  }
}