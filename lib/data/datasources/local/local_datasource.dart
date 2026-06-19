import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:axon/data/models/conversation_model.dart';
import 'package:axon/data/models/message_model.dart';
import 'package:axon/core/errors/exceptions.dart';

abstract class LocalDatasource {
  Future<List<ConversationModel>> getAllConversations();
  Future<ConversationModel?> getConversationById(String id);
  Future<ConversationModel> createConversation(String title);
  Future<ConversationModel> updateConversation(ConversationModel model);
  Future<void> deleteConversation(String id);
  Future<List<ConversationModel>> searchConversations(String query);
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> saveMessage(MessageModel model);
  Future<void> updateMessage(MessageModel model);
  Future<void> deleteMessage(String messageId);
  Future<List<MessageModel>> searchMessages(String query);
  Stream<List<ConversationModel>> watchConversations();
}

class HiveLocalDatasource implements LocalDatasource {
  final Box<ConversationModel> _conversationBox;
  final Box<MessageModel> _messageBox;
  final _uuid = const Uuid();

  HiveLocalDatasource({
    required Box<ConversationModel> conversationBox,
    required Box<MessageModel> messageBox,
  })  : _conversationBox = conversationBox,
        _messageBox = messageBox;

  @override
  Future<List<ConversationModel>> getAllConversations() async {
    try {
      final list = _conversationBox.values.toList();
      list.sort((a, b) {
        final aPinned = a.isPinned ?? false;
        final bPinned = b.isPinned ?? false;
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    } catch (e) {
      throw LocalStorageException('Failed to fetch conversations: $e');
    }
  }

  @override
  Future<ConversationModel?> getConversationById(String id) async {
    try {
      return _conversationBox.get(id);
    } catch (e) {
      throw LocalStorageException('Failed to get conversation: $e');
    }
  }

  @override
  Future<ConversationModel> createConversation(String title) async {
    try {
      final model = ConversationModel(
        id: _uuid.v4(),
        title: title.isEmpty ? 'New conversation' : title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _conversationBox.put(model.id, model);
      return model;
    } catch (e) {
      throw LocalStorageException('Failed to create conversation: $e');
    }
  }

  @override
  Future<ConversationModel> updateConversation(ConversationModel model) async {
    try {
      await _conversationBox.put(model.id, model);
      return model;
    } catch (e) {
      throw LocalStorageException('Failed to update conversation: $e');
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _conversationBox.delete(id);
      final msgKeys = _messageBox.values
          .where((m) => m.conversationId == id)
          .map((m) => m.id)
          .toList();
      await _messageBox.deleteAll(msgKeys);
    } catch (e) {
      throw LocalStorageException('Failed to delete conversation: $e');
    }
  }

  @override
  Future<List<ConversationModel>> searchConversations(String query) async {
    try {
      final lower = query.toLowerCase();
      return _conversationBox.values
          .where((c) => c.title.toLowerCase().contains(lower))
          .toList();
    } catch (e) {
      throw LocalStorageException('Failed to search conversations: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final msgs = _messageBox.values
          .where((m) => m.conversationId == conversationId)
          .toList();
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    } catch (e) {
      throw LocalStorageException('Failed to fetch messages: $e');
    }
  }

  @override
  Future<MessageModel> saveMessage(MessageModel model) async {
    try {
      await _messageBox.put(model.id, model);
      final conv = _conversationBox.get(model.conversationId);
      if (conv != null) {
        conv.updatedAt = DateTime.now();
        conv.messageCount = _messageBox.values
            .where((m) => m.conversationId == model.conversationId)
            .length;
        
        final prefix = model.role == 'user' ? 'You: ' : 'AI: ';
        String previewText = model.content.trim();
        if (model.attachmentPaths != null && model.attachmentPaths!.isNotEmpty) {
          previewText = '📷 [Image] $previewText';
        }
        if (previewText.isEmpty) previewText = 'Attachment';
        conv.lastMessagePreview = previewText.length > 60
            ? '$prefix${previewText.substring(0, 60)}...'
            : '$prefix$previewText';
            
        await _conversationBox.put(conv.id, conv);
      }
      return model;
    } catch (e) {
      throw LocalStorageException('Failed to save message: $e');
    }
  }

  @override
  Future<void> updateMessage(MessageModel model) async {
    try {
      await _messageBox.put(model.id, model);
    } catch (e) {
      throw LocalStorageException('Failed to update message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageBox.delete(messageId);
    } catch (e) {
      throw LocalStorageException('Failed to delete message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String query) async {
    try {
      final lower = query.toLowerCase();
      return _messageBox.values
          .where((m) => m.content.toLowerCase().contains(lower))
          .toList();
    } catch (e) {
      throw LocalStorageException('Failed to search messages: $e');
    }
  }

  @override
  Stream<List<ConversationModel>> watchConversations() {
    return _conversationBox.watch().map((_) {
      final list = _conversationBox.values.toList();
      list.sort((a, b) {
        final aPinned = a.isPinned ?? false;
        final bPinned = b.isPinned ?? false;
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }
}
