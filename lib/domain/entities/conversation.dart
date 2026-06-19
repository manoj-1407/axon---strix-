import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessagePreview;
  final bool isPinned;
  final bool isUnread;
  final List<String> tags;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessagePreview,
    this.isPinned = false,
    this.isUnread = false,
    this.tags = const [],
  });

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessagePreview,
    bool? isPinned,
    bool? isUnread,
    List<String>? tags,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isPinned: isPinned ?? this.isPinned,
      isUnread: isUnread ?? this.isUnread,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, createdAt, updatedAt, messageCount, lastMessagePreview, isPinned, isUnread, tags];
}
