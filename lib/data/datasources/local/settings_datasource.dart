import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:axon/data/models/ai_provider_model.dart';
import 'package:axon/core/constants/app_constants.dart';
import 'package:axon/core/errors/exceptions.dart';

abstract class SettingsDatasource {
  Future<List<AiProviderModel>> getAllProviders();
  Future<AiProviderModel?> getActiveProvider();
  Future<AiProviderModel> saveProvider(AiProviderModel model);
  Future<void> updateProvider(AiProviderModel model);
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

class HiveSettingsDatasource implements SettingsDatasource {
  final Box<AiProviderModel> _providerBox;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  HiveSettingsDatasource({
    required Box<AiProviderModel> providerBox,
    required SharedPreferences prefs,
  })  : _providerBox = providerBox,
        _prefs = prefs;

  @override
  Future<List<AiProviderModel>> getAllProviders() async {
    try {
      return _providerBox.values.toList();
    } catch (e) {
      throw LocalStorageException('Failed to fetch providers: $e');
    }
  }

  @override
  Future<AiProviderModel?> getActiveProvider() async {
    try {
      final activeId = _prefs.getString(AppConstants.prefActiveProviderId);
      if (activeId == null) return null;
      return _providerBox.get(activeId);
    } catch (e) {
      throw LocalStorageException('Failed to get active provider: $e');
    }
  }

  @override
  Future<AiProviderModel> saveProvider(AiProviderModel model) async {
    try {
      final id = model.id.isEmpty ? _uuid.v4() : model.id;
      final newModel = AiProviderModel(
        id: id,
        name: model.name,
        type: model.type,
        baseUrl: model.baseUrl,
        apiKey: model.apiKey,
        model: model.model,
        isActive: model.isActive,
        createdAt: model.createdAt,
      );
      await _providerBox.put(id, newModel);
      return newModel;
    } catch (e) {
      throw LocalStorageException('Failed to save provider: $e');
    }
  }

  @override
  Future<void> updateProvider(AiProviderModel model) async {
    try {
      await _providerBox.put(model.id, model);
    } catch (e) {
      throw LocalStorageException('Failed to update provider: $e');
    }
  }

  @override
  Future<void> deleteProvider(String providerId) async {
    try {
      await _providerBox.delete(providerId);
      final activeId = _prefs.getString(AppConstants.prefActiveProviderId);
      if (activeId == providerId) {
        await _prefs.remove(AppConstants.prefActiveProviderId);
      }
    } catch (e) {
      throw LocalStorageException('Failed to delete provider: $e');
    }
  }

  @override
  Future<void> setActiveProvider(String providerId) async {
    try {
      await _prefs.setString(AppConstants.prefActiveProviderId, providerId);
    } catch (e) {
      throw LocalStorageException('Failed to set active provider: $e');
    }
  }

  @override
  Future<bool> getStreamingEnabled() async =>
      _prefs.getBool(AppConstants.prefStreamingEnabled) ?? true;

  @override
  Future<void> setStreamingEnabled(bool enabled) async =>
      _prefs.setBool(AppConstants.prefStreamingEnabled, enabled);

  @override
  Future<String> getThemeMode() async =>
      _prefs.getString(AppConstants.prefThemeMode) ?? 'dark';

  @override
  Future<void> setThemeMode(String mode) async =>
      _prefs.setString(AppConstants.prefThemeMode, mode);

  @override
  Future<String> getThemePreset() async =>
      _prefs.getString(AppConstants.prefThemePreset) ?? 'terminal';

  @override
  Future<void> setThemePreset(String preset) async =>
      _prefs.setString(AppConstants.prefThemePreset, preset);

  @override
  Future<bool> getSoundEnabled() async =>
      _prefs.getBool(AppConstants.prefSoundEnabled) ?? true;

  @override
  Future<void> setSoundEnabled(bool enabled) async =>
      _prefs.setBool(AppConstants.prefSoundEnabled, enabled);

  @override
  Future<String?> getConversationModel(String conversationId) async =>
      _prefs.getString('${AppConstants.prefConversationModelPrefix}$conversationId');

  @override
  Future<void> setConversationModel(String conversationId, String? model) async {
    final key = '${AppConstants.prefConversationModelPrefix}$conversationId';
    if (model == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, model);
    }
  }

  @override
  Future<String?> getSystemPrompt(String conversationId) async =>
      _prefs.getString('${AppConstants.prefSystemPromptPrefix}$conversationId');

  @override
  Future<void> setSystemPrompt(String conversationId, String prompt) async =>
      _prefs.setString('${AppConstants.prefSystemPromptPrefix}$conversationId', prompt);
}
