import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId;

  @HiveField(2)
  String role;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String status;

  @HiveField(6)
  String? errorMessage;

  @HiveField(7)
  int? tokenCount;

  @HiveField(8)
  List<String>? attachmentPaths;

  @HiveField(9)
  bool? isEdited;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.tokenCount,
    this.attachmentPaths,
    this.isEdited,
  });
}
