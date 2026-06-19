import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/domain/entities/message.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getAllConversations();
  Future<Conversation?> getConversationById(String id);
  Future<Conversation> createConversation(String title);
  Future<Conversation> updateConversation(Conversation conversation);
  Future<void> deleteConversation(String id);
  Future<List<Conversation>> searchConversations(String query);
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> saveMessage(Message message);
  Future<void> updateMessage(Message message);
  Future<void> deleteMessage(String messageId);
  Future<List<Message>> searchMessages(String query);
  Stream<List<Conversation>> watchConversations();
}
