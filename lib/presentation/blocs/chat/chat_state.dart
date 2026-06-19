import 'package:equatable/equatable.dart';
import 'package:axon/domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  final List<Message> messages;
  const ChatLoading({this.messages = const []});

  @override
  List<Object?> get props => [messages];
}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final String conversationId;
  final String? modelOverride;
  final String? systemPrompt;

  const ChatLoaded({
    required this.messages,
    required this.conversationId,
    this.modelOverride,
    this.systemPrompt,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    String? conversationId,
    String? modelOverride,
    String? systemPrompt,
    bool clearModelOverride = false,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      modelOverride: clearModelOverride ? null : modelOverride ?? this.modelOverride,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, modelOverride, systemPrompt];
}

class ChatSending extends ChatState {
  final List<Message> messages;
  final String conversationId;

  const ChatSending({
    required this.messages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}

class ChatStreaming extends ChatState {
  final List<Message> messages;
  final String conversationId;
  final String streamingContent;
  final String streamingMessageId;

  const ChatStreaming({
    required this.messages,
    required this.conversationId,
    required this.streamingContent,
    required this.streamingMessageId,
  });

  ChatStreaming copyWith({
    List<Message>? messages,
    String? conversationId,
    String? streamingContent,
    String? streamingMessageId,
  }) {
    return ChatStreaming(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      streamingContent: streamingContent ?? this.streamingContent,
      streamingMessageId: streamingMessageId ?? this.streamingMessageId,
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, streamingContent, streamingMessageId];
}

class ChatSuccess extends ChatState {
  final List<Message> messages;
  final String conversationId;
  final Message lastAssistantMessage;
  final String? modelOverride;
  final String? systemPrompt;

  const ChatSuccess({
    required this.messages,
    required this.conversationId,
    required this.lastAssistantMessage,
    this.modelOverride,
    this.systemPrompt,
  });

  @override
  List<Object?> get props => [messages, conversationId, lastAssistantMessage, modelOverride, systemPrompt];
}

class ChatError extends ChatState {
  final List<Message> messages;
  final String conversationId;
  final String error;
  final bool canRetry;
  final int retrySeconds;

  const ChatError({
    required this.messages,
    required this.conversationId,
    required this.error,
    this.canRetry = true,
    this.retrySeconds = 0,
  });

  ChatError copyWith({
    List<Message>? messages,
    String? conversationId,
    String? error,
    bool? canRetry,
    int? retrySeconds,
  }) {
    return ChatError(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      error: error ?? this.error,
      canRetry: canRetry ?? this.canRetry,
      retrySeconds: retrySeconds ?? this.retrySeconds,
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, error, canRetry, retrySeconds];
}

class ChatProviderNotConfigured extends ChatState {
  const ChatProviderNotConfigured();
}
