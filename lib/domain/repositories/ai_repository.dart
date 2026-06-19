import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/domain/entities/message.dart';

class AiResponse {
  final String content;
  final int? tokenCount;

  const AiResponse({required this.content, this.tokenCount});
}

abstract class AiRepository {
  Future<AiResponse> sendMessage({
    required List<Message> messages,
    required AiProvider provider,
  });

  Stream<String> sendMessageStream({
    required List<Message> messages,
    required AiProvider provider,
  });

  Future<bool> testConnection(AiProvider provider);
  Future<List<String>> fetchAvailableModels(AiProvider provider);
}
