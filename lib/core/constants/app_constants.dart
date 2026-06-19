class AppConstants {
  static const String appName = 'AXON';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'precision intelligence';

  static const String hiveConversationBox = 'conversations';
  static const String hiveMessageBox = 'messages';
  static const String hiveProviderBox = 'providers';
  static const String hiveSettingsBox = 'settings';

  static const String prefThemeMode = 'theme_mode';
  static const String prefThemePreset = 'theme_preset';
  static const String prefActiveProviderId = 'active_provider_id';
  static const String prefStreamingEnabled = 'streaming_enabled';
  static const String prefSoundEnabled = 'sound_enabled';

  // Per-conversation keys (use with conversationId suffix)
  static const String prefConversationModelPrefix = 'model_';
  static const String prefSystemPromptPrefix = 'sysprompt_';

  static const int requestTimeoutSeconds = 60;
  static const int streamTimeoutSeconds = 120;
  static const int maxMessageLength = 32000;

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String lmStudioBaseUrl = 'http://localhost:1234/v1';

  static const String defaultOpenAiModel = 'gpt-4o-mini';
  static const String defaultGeminiModel = 'gemini-2.0-flash';
  static const String defaultOpenRouterModel = 'openai/gpt-4o-mini';
}
