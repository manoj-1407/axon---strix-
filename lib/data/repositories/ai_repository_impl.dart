import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/domain/repositories/ai_repository.dart';
import 'package:axon/domain/repositories/settings_repository.dart';
import 'package:axon/data/datasources/local/settings_datasource.dart';
import 'package:axon/data/datasources/remote/ai_remote_datasource.dart';
import 'package:axon/data/models/model_mappers.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDatasource _remote;

  AiRepositoryImpl(this._remote);

  @override
  Future<AiResponse> sendMessage({
    required List<Message> messages,
    required AiProvider provider,
  }) =>
      _remote.sendMessage(messages: messages, provider: provider);

  @override
  Stream<String> sendMessageStream({
    required List<Message> messages,
    required AiProvider provider,
  }) =>
      _remote.sendMessageStream(messages: messages, provider: provider);

  @override
  Future<bool> testConnection(AiProvider provider) =>
      _remote.testConnection(provider);

  @override
  Future<List<String>> fetchAvailableModels(AiProvider provider) =>
      _remote.fetchAvailableModels(provider);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDatasource _datasource;

  SettingsRepositoryImpl(this._datasource);

  @override
  Future<List<AiProvider>> getAllProviders() async {
    final models = await _datasource.getAllProviders();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AiProvider?> getActiveProvider() async {
    final model = await _datasource.getActiveProvider();
    return model?.toEntity();
  }

  @override
  Future<AiProvider> saveProvider(AiProvider provider) async {
    final model = await _datasource.saveProvider(provider.toModel());
    return model.toEntity();
  }

  @override
  Future<void> updateProvider(AiProvider provider) =>
      _datasource.updateProvider(provider.toModel());

  @override
  Future<void> deleteProvider(String providerId) =>
      _datasource.deleteProvider(providerId);

  @override
  Future<void> setActiveProvider(String providerId) =>
      _datasource.setActiveProvider(providerId);

  @override
  Future<bool> getStreamingEnabled() => _datasource.getStreamingEnabled();

  @override
  Future<void> setStreamingEnabled(bool enabled) =>
      _datasource.setStreamingEnabled(enabled);

  @override
  Future<String> getThemeMode() => _datasource.getThemeMode();

  @override
  Future<void> setThemeMode(String mode) => _datasource.setThemeMode(mode);

  @override
  Future<String> getThemePreset() => _datasource.getThemePreset();

  @override
  Future<void> setThemePreset(String preset) => _datasource.setThemePreset(preset);

  @override
  Future<bool> getSoundEnabled() => _datasource.getSoundEnabled();

  @override
  Future<void> setSoundEnabled(bool enabled) =>
      _datasource.setSoundEnabled(enabled);

  @override
  Future<String?> getConversationModel(String conversationId) =>
      _datasource.getConversationModel(conversationId);

  @override
  Future<void> setConversationModel(String conversationId, String? model) =>
      _datasource.setConversationModel(conversationId, model);

  @override
  Future<String?> getSystemPrompt(String conversationId) =>
      _datasource.getSystemPrompt(conversationId);

  @override
  Future<void> setSystemPrompt(String conversationId, String prompt) =>
      _datasource.setSystemPrompt(conversationId, prompt);
}
