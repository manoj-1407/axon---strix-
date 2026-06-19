import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

enum MessageStatus { sending, sent, error, streaming }

class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final int? tokenCount;
  final List<String>? attachmentPaths;
  final bool isEdited;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.errorMessage,
    this.tokenCount,
    this.attachmentPaths,
    this.isEdited = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
    int? tokenCount,
    List<String>? attachmentPaths,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      tokenCount: tokenCount ?? this.tokenCount,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get hasError => status == MessageStatus.error;

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, timestamp, status, errorMessage, tokenCount, attachmentPaths, isEdited];
}
