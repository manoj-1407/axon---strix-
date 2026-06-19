import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/data/models/conversation_model.dart';
import 'package:axon/data/models/message_model.dart';
import 'package:axon/data/models/ai_provider_model.dart';

extension ConversationModelMapper on ConversationModel {
  Conversation toEntity() => Conversation(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messageCount: messageCount,
        lastMessagePreview: lastMessagePreview,
        isPinned: isPinned ?? false,
        isUnread: isUnread ?? false,
        tags: tags ?? const [],
      );
}

extension ConversationMapper on Conversation {
  ConversationModel toModel() => ConversationModel(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messageCount: messageCount,
        lastMessagePreview: lastMessagePreview,
        isPinned: isPinned,
        isUnread: isUnread,
        tags: tags,
      );
}

extension MessageModelMapper on MessageModel {
  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        role: _roleFromString(role),
        content: content,
        timestamp: timestamp,
        status: _statusFromString(status),
        errorMessage: errorMessage,
        tokenCount: tokenCount,
        attachmentPaths: attachmentPaths,
        isEdited: isEdited ?? false,
      );

  MessageRole _roleFromString(String r) {
    switch (r) {
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  MessageStatus _statusFromString(String s) {
    switch (s) {
      case 'sending':
        return MessageStatus.sending;
      case 'error':
        return MessageStatus.error;
      case 'streaming':
        return MessageStatus.streaming;
      default:
        return MessageStatus.sent;
    }
  }
}

extension MessageMapper on Message {
  MessageModel toModel() => MessageModel(
        id: id,
        conversationId: conversationId,
        role: role.name,
        content: content,
        timestamp: timestamp,
        status: status.name,
        errorMessage: errorMessage,
        tokenCount: tokenCount,
        attachmentPaths: attachmentPaths,
        isEdited: isEdited,
      );
}

extension AiProviderModelMapper on AiProviderModel {
  AiProvider toEntity() => AiProvider(
        id: id,
        name: name,
        type: _typeFromString(type),
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        isActive: isActive,
        createdAt: createdAt,
      );

  ProviderType _typeFromString(String t) {
    switch (t) {
      case 'gemini':
        return ProviderType.gemini;
      case 'openRouter':
        return ProviderType.openRouter;
      case 'lmStudio':
        return ProviderType.lmStudio;
      case 'openai':
        return ProviderType.openai;
      default:
        return ProviderType.custom;
    }
  }
}

extension AiProviderMapper on AiProvider {
  AiProviderModel toModel() => AiProviderModel(
        id: id,
        name: name,
        type: type.name,
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        isActive: isActive,
        createdAt: createdAt,
      );
}
