import 'package:axon/domain/entities/ai_provider.dart';

abstract class SettingsRepository {
  Future<List<AiProvider>> getAllProviders();
  Future<AiProvider?> getActiveProvider();
  Future<AiProvider> saveProvider(AiProvider provider);
  Future<void> updateProvider(AiProvider provider);
  Future<void> deleteProvider(String providerId);
  Future<void> setActiveProvider(String providerId);
  Future<bool> getStreamingEnabled();
  Future<void> setStreamingEnabled(bool enabled);
  Future<String> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String> getThemePreset();
  Future<void> setThemePreset(String preset);
  Future<bool> getSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);
  // Per-conversation
  Future<String?> getConversationModel(String conversationId);
  Future<void> setConversationModel(String conversationId, String? model);
  Future<String?> getSystemPrompt(String conversationId);
  Future<void> setSystemPrompt(String conversationId, String prompt);
}
