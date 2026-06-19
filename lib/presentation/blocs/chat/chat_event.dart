import 'package:equatable/equatable.dart';
import 'package:axon/domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final String content;
  final String conversationId;
  final List<String>? attachmentPaths;
  const SendMessage({required this.content, required this.conversationId, this.attachmentPaths});

  @override
  List<Object?> get props => [content, conversationId, attachmentPaths];
}

class SendMessageStream extends ChatEvent {
  final String content;
  final String conversationId;
  final List<String>? attachmentPaths;
  const SendMessageStream({required this.content, required this.conversationId, this.attachmentPaths});

  @override
  List<Object?> get props => [content, conversationId, attachmentPaths];
}

class StreamTokenReceived extends ChatEvent {
  final String token;
  const StreamTokenReceived(this.token);

  @override
  List<Object?> get props => [token];
}

class StreamCompleted extends ChatEvent {
  const StreamCompleted();
}

class StreamError extends ChatEvent {
  final String error;
  const StreamError(this.error);

  @override
  List<Object?> get props => [error];
}

class RetryLastMessage extends ChatEvent {
  const RetryLastMessage();
}

class ClearChat extends ChatEvent {
  const ClearChat();
}

class DeleteMessage extends ChatEvent {
  final String messageId;
  const DeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class CopyMessage extends ChatEvent {
  final String content;
  const CopyMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class ChangeConversationModel extends ChatEvent {
  final String? model; // null = use provider default
  const ChangeConversationModel(this.model);

  @override
  List<Object?> get props => [model];
}

class UpdateSystemPrompt extends ChatEvent {
  final String prompt;
  const UpdateSystemPrompt(this.prompt);

  @override
  List<Object?> get props => [prompt];
}

class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;
  const EditMessage({required this.messageId, required this.newContent});

  @override
  List<Object?> get props => [messageId, newContent];
}

class RetryCountdownTick extends ChatEvent {
  final List<Message> messages;
  final String conversationId;
  final String error;
  final int seconds;

  const RetryCountdownTick({
    required this.messages,
    required this.conversationId,
    required this.error,
    required this.seconds,
  });

  @override
  List<Object?> get props => [messages, conversationId, error, seconds];
}
