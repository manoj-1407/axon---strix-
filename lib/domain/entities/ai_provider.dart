import 'package:equatable/equatable.dart';

enum ProviderType { openai, gemini, openRouter, lmStudio, custom }

class AiProvider extends Equatable {
  final String id;
  final String name;
  final ProviderType type;
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool isActive;
  final DateTime createdAt;

  const AiProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.isActive = false,
    required this.createdAt,
  });

  AiProvider copyWith({
    String? id,
    String? name,
    ProviderType? type,
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AiProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isGemini => type == ProviderType.gemini;
  bool get isOpenAiCompatible =>
      type == ProviderType.openai ||
      type == ProviderType.openRouter ||
      type == ProviderType.lmStudio ||
      type == ProviderType.custom;

  String get displayName {
    switch (type) {
      case ProviderType.openai:
        return 'OpenAI';
      case ProviderType.gemini:
        return 'Google Gemini';
      case ProviderType.openRouter:
        return 'OpenRouter';
      case ProviderType.lmStudio:
        return 'LM Studio';
      case ProviderType.custom:
        return name;
    }
  }

  @override
  List<Object?> get props =>
      [id, name, type, baseUrl, apiKey, model, isActive, createdAt];
}
