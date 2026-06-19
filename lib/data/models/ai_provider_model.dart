import 'package:hive/hive.dart';

part 'ai_provider_model.g.dart';

@HiveType(typeId: 2)
class AiProviderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  String baseUrl;

  @HiveField(4)
  String apiKey;

  @HiveField(5)
  String model;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime createdAt;

  AiProviderModel({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.isActive,
    required this.createdAt,
  });
}
