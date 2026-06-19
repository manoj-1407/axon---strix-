import 'package:equatable/equatable.dart';
import 'package:axon/domain/entities/ai_provider.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class AddProvider extends SettingsEvent {
  final AiProvider provider;
  const AddProvider(this.provider);
  @override
  List<Object?> get props => [provider];
}

class UpdateProvider extends SettingsEvent {
  final AiProvider provider;
  const UpdateProvider(this.provider);
  @override
  List<Object?> get props => [provider];
}

class DeleteProvider extends SettingsEvent {
  final String providerId;
  const DeleteProvider(this.providerId);
  @override
  List<Object?> get props => [providerId];
}

class SetActiveProvider extends SettingsEvent {
  final String providerId;
  const SetActiveProvider(this.providerId);
  @override
  List<Object?> get props => [providerId];
}

class ToggleStreaming extends SettingsEvent {
  final bool enabled;
  const ToggleStreaming(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class ChangeTheme extends SettingsEvent {
  final String mode;
  const ChangeTheme(this.mode);
  @override
  List<Object?> get props => [mode];
}

class ChangeThemePreset extends SettingsEvent {
  final String preset;
  const ChangeThemePreset(this.preset);
  @override
  List<Object?> get props => [preset];
}

class ToggleSound extends SettingsEvent {
  final bool enabled;
  const ToggleSound(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class TestProviderConnection extends SettingsEvent {
  final AiProvider provider;
  const TestProviderConnection(this.provider);
  @override
  List<Object?> get props => [provider];
}

class FetchModels extends SettingsEvent {
  final AiProvider provider;
  const FetchModels(this.provider);
  @override
  List<Object?> get props => [provider];
}

class ExportBackup extends SettingsEvent {
  final String filePath;
  const ExportBackup(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class ImportBackup extends SettingsEvent {
  final String filePath;
  const ImportBackup(this.filePath);
  @override
  List<Object?> get props => [filePath];
}
