import 'package:hive/hive.dart';

part 'conversation_model.g.dart';

@HiveType(typeId: 0)
class ConversationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  int messageCount;

  @HiveField(5)
  String? lastMessagePreview;

  @HiveField(6)
  bool? isPinned;

  @HiveField(7)
  bool? isUnread;

  @HiveField(8)
  List<String>? tags;

  ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessagePreview,
    this.isPinned,
    this.isUnread,
    this.tags,
  });
}
