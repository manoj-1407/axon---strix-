import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/domain/repositories/ai_repository.dart';
import 'package:axon/domain/repositories/settings_repository.dart';
import 'package:axon/presentation/blocs/settings/settings_event.dart';
import 'package:axon/presentation/blocs/settings/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepo;
  final AiRepository _aiRepo;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required AiRepository aiRepository,
  })  : _settingsRepo = settingsRepository,
        _aiRepo = aiRepository,
        super(const SettingsLoading()) {
    on<LoadSettings>(_onLoad);
    on<AddProvider>(_onAddProvider);
    on<UpdateProvider>(_onUpdateProvider);
    on<DeleteProvider>(_onDeleteProvider);
    on<SetActiveProvider>(_onSetActive);
    on<ToggleStreaming>(_onToggleStreaming);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeThemePreset>(_onChangeThemePreset);
    on<ToggleSound>(_onToggleSound);
    on<TestProviderConnection>(_onTestConnection);
    on<FetchModels>(_onFetchModels);
    on<ExportBackup>(_onExportBackup);
    on<ImportBackup>(_onImportBackup);

    add(const LoadSettings());
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final results = await Future.wait([
        _settingsRepo.getAllProviders(),
        _settingsRepo.getActiveProvider(),
        _settingsRepo.getStreamingEnabled(),
        _settingsRepo.getThemeMode(),
        _settingsRepo.getThemePreset(),
        _settingsRepo.getSoundEnabled(),
      ]);

      emit(SettingsLoaded(
        providers: results[0] as dynamic,
        activeProvider: results[1] as dynamic,
        streamingEnabled: results[2] as bool,
        themeMode: results[3] as String,
        themePreset: results[4] as String,
        soundEnabled: results[5] as bool,
      ));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onAddProvider(AddProvider event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      final saved = await _settingsRepo.saveProvider(event.provider);
      final updated = [...current.providers, saved];
      if (updated.length == 1) {
        await _settingsRepo.setActiveProvider(saved.id);
        emit(current.copyWith(providers: updated, activeProvider: saved));
      } else {
        emit(current.copyWith(providers: updated));
      }
    } catch (e) {
      emit(SettingsError('Failed to add provider: $e'));
    }
  }

  Future<void> _onUpdateProvider(UpdateProvider event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      await _settingsRepo.updateProvider(event.provider);
      final updated = current.providers
          .map((p) => p.id == event.provider.id ? event.provider : p)
          .toList();
      final newActive = current.activeProvider?.id == event.provider.id
          ? event.provider
          : current.activeProvider;
      emit(current.copyWith(providers: updated, activeProvider: newActive));
    } catch (e) {
      emit(SettingsError('Failed to update provider: $e'));
    }
  }

  Future<void> _onDeleteProvider(DeleteProvider event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      await _settingsRepo.deleteProvider(event.providerId);
      final updated = current.providers.where((p) => p.id != event.providerId).toList();
      final wasActive = current.activeProvider?.id == event.providerId;
      emit(current.copyWith(providers: updated, clearActiveProvider: wasActive));
    } catch (e) {
      emit(SettingsError('Failed to delete provider: $e'));
    }
  }

  Future<void> _onSetActive(SetActiveProvider event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      await _settingsRepo.setActiveProvider(event.providerId);
      final provider = current.providers.firstWhere((p) => p.id == event.providerId);
      emit(current.copyWith(activeProvider: provider));
    } catch (e) {
      emit(SettingsError('Failed to set active provider: $e'));
    }
  }

  Future<void> _onToggleStreaming(ToggleStreaming event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    await _settingsRepo.setStreamingEnabled(event.enabled);
    emit(current.copyWith(streamingEnabled: event.enabled));
  }

  Future<void> _onChangeTheme(ChangeTheme event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    await _settingsRepo.setThemeMode(event.mode);
    emit(current.copyWith(themeMode: event.mode));
  }

  Future<void> _onChangeThemePreset(ChangeThemePreset event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    await _settingsRepo.setThemePreset(event.preset);
    emit(current.copyWith(themePreset: event.preset));
  }

  Future<void> _onToggleSound(ToggleSound event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    await _settingsRepo.setSoundEnabled(event.enabled);
    emit(current.copyWith(soundEnabled: event.enabled));
  }

  Future<void> _onTestConnection(TestProviderConnection event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    emit(current.copyWith(isTestingConnection: true, clearConnectionResult: true));
    final result = await _aiRepo.testConnection(event.provider);
    emit((state as SettingsLoaded).copyWith(isTestingConnection: false, connectionTestResult: result));
  }

  Future<void> _onFetchModels(FetchModels event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    emit(current.copyWith(isFetchingModels: true));
    final models = await _aiRepo.fetchAvailableModels(event.provider);
    emit((state as SettingsLoaded).copyWith(isFetchingModels: false, availableModels: models));
  }

  Future<void> _onExportBackup(ExportBackup event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      final providersJson = current.providers.map((p) => {
        'id': p.id,
        'name': p.name,
        'type': p.type.name,
        'baseUrl': p.baseUrl,
        'apiKey': p.apiKey,
        'model': p.model,
        'isActive': current.activeProvider?.id == p.id,
        'createdAt': p.createdAt.toIso8601String(),
      }).toList();

      final backup = {
        'version': 1,
        'providers': providersJson,
        'preferences': {
          'streamingEnabled': current.streamingEnabled,
          'soundEnabled': current.soundEnabled,
          'themePreset': current.themePreset,
          'themeMode': current.themeMode,
        }
      };

      final file = File(event.filePath);
      await file.writeAsString(jsonEncode(backup));
    } catch (_) {}
  }

  Future<void> _onImportBackup(ImportBackup event, Emitter<SettingsState> emit) async {
    if (state is! SettingsLoaded) return;
    final current = state as SettingsLoaded;
    try {
      final file = File(event.filePath);
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final backup = jsonDecode(contents) as Map<String, dynamic>;
      if (backup['version'] != 1) return;

      final providersJson = backup['providers'] as List;
      final preferences = backup['preferences'] as Map<String, dynamic>;

      final streaming = preferences['streamingEnabled'] as bool? ?? true;
      final sound = preferences['soundEnabled'] as bool? ?? true;
      final themePreset = preferences['themePreset'] as String? ?? 'terminal';
      final themeMode = preferences['themeMode'] as String? ?? 'dark';

      await _settingsRepo.setStreamingEnabled(streaming);
      await _settingsRepo.setSoundEnabled(sound);
      await _settingsRepo.setThemePreset(themePreset);
      await _settingsRepo.setThemeMode(themeMode);

      final List<AiProvider> newProviders = [];
      AiProvider? newActive;

      for (final p in current.providers) {
        await _settingsRepo.deleteProvider(p.id);
      }

      for (final item in providersJson) {
        final map = item as Map<String, dynamic>;
        final provider = AiProvider(
          id: map['id'] as String,
          name: map['name'] as String,
          type: ProviderType.values.firstWhere((t) => t.name == map['type'], orElse: () => ProviderType.custom),
          baseUrl: map['baseUrl'] as String,
          apiKey: map['apiKey'] as String,
          model: map['model'] as String,
          createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        );
        final saved = await _settingsRepo.saveProvider(provider);
        newProviders.add(saved);
        if (map['isActive'] == true) {
          newActive = saved;
        }
      }

      if (newActive != null) {
        await _settingsRepo.setActiveProvider(newActive.id);
      } else if (newProviders.isNotEmpty) {
        newActive = newProviders.first;
        await _settingsRepo.setActiveProvider(newActive.id);
      }

      emit(SettingsLoaded(
        providers: newProviders,
        activeProvider: newActive,
        streamingEnabled: streaming,
        soundEnabled: sound,
        themePreset: themePreset,
        themeMode: themeMode,
      ));
    } catch (_) {}
  }
}
