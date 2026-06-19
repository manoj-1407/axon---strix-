import 'package:equatable/equatable.dart';
import 'package:axon/domain/entities/ai_provider.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final List<AiProvider> providers;
  final AiProvider? activeProvider;
  final bool streamingEnabled;
  final String themeMode;
  final String themePreset;
  final bool soundEnabled;
  final bool isTestingConnection;
  final bool? connectionTestResult;
  final List<String> availableModels;
  final bool isFetchingModels;

  const SettingsLoaded({
    required this.providers,
    this.activeProvider,
    required this.streamingEnabled,
    required this.themeMode,
    required this.themePreset,
    required this.soundEnabled,
    this.isTestingConnection = false,
    this.connectionTestResult,
    this.availableModels = const [],
    this.isFetchingModels = false,
  });

  SettingsLoaded copyWith({
    List<AiProvider>? providers,
    AiProvider? activeProvider,
    bool? streamingEnabled,
    String? themeMode,
    String? themePreset,
    bool? soundEnabled,
    bool? isTestingConnection,
    bool? connectionTestResult,
    List<String>? availableModels,
    bool? isFetchingModels,
    bool clearActiveProvider = false,
    bool clearConnectionResult = false,
  }) {
    return SettingsLoaded(
      providers: providers ?? this.providers,
      activeProvider: clearActiveProvider ? null : activeProvider ?? this.activeProvider,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isTestingConnection: isTestingConnection ?? this.isTestingConnection,
      connectionTestResult: clearConnectionResult ? null : connectionTestResult ?? this.connectionTestResult,
      availableModels: availableModels ?? this.availableModels,
      isFetchingModels: isFetchingModels ?? this.isFetchingModels,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        activeProvider,
        streamingEnabled,
        themeMode,
        themePreset,
        soundEnabled,
        isTestingConnection,
        connectionTestResult,
        availableModels,
        isFetchingModels,
      ];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}
