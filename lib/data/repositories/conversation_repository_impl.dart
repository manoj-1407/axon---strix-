import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/domain/repositories/conversation_repository.dart';
import 'package:axon/data/datasources/local/local_datasource.dart';
import 'package:axon/data/models/model_mappers.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final LocalDatasource _local;

  ConversationRepositoryImpl(this._local);

  @override
  Future<List<Conversation>> getAllConversations() async {
    final models = await _local.getAllConversations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Conversation?> getConversationById(String id) async {
    final model = await _local.getConversationById(id);
    return model?.toEntity();
  }

  @override
  Future<Conversation> createConversation(String title) async {
    final model = await _local.createConversation(title);
    return model.toEntity();
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    final model = await _local.updateConversation(conversation.toModel());
    return model.toEntity();
  }

  @override
  Future<void> deleteConversation(String id) =>
      _local.deleteConversation(id);

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final models = await _local.searchConversations(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final models = await _local.getMessages(conversationId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Message> saveMessage(Message message) async {
    final model = await _local.saveMessage(message.toModel());
    return model.toEntity();
  }

  @override
  Future<void> updateMessage(Message message) =>
      _local.updateMessage(message.toModel());

  @override
  Future<void> deleteMessage(String messageId) =>
      _local.deleteMessage(messageId);

  @override
  Future<List<Message>> searchMessages(String query) async {
    final models = await _local.searchMessages(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    return _local
        .watchConversations()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
