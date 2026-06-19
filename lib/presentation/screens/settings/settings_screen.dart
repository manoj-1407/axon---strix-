import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:axon/core/constants/app_constants.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/domain/entities/ai_provider.dart';
import 'package:axon/presentation/blocs/settings/settings_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_event.dart';
import 'package:axon/presentation/blocs/settings/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(),
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoading) {
                    return Center(
                      child: Text('loading_', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13)),
                    );
                  }
                  if (state is SettingsLoaded) return _SettingsBody(state: state);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(border: Border.all(color: C.border)),
              child: const Icon(Icons.arrow_back_rounded, color: C.grey1, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('settings',
                  style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 16, fontWeight: FontWeight.w700)),
              Text('axon / config', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final SettingsLoaded state;
  const _SettingsBody({required this.state});

  Future<void> _exportBackup(BuildContext context) async {
    final bloc = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? path;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        path = await FilePicker.platform.saveFile(
          dialogTitle: 'Select backup location',
          fileName: 'axon_backup.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      }
      if (path == null) {
        final dir = await getApplicationDocumentsDirectory();
        path = '${dir.path}/axon_backup.json';
      }

      bloc.add(ExportBackup(path));
      messenger.showSnackBar(
        SnackBar(
          content: Text('settings backed up to $path', style: GoogleFonts.spaceGrotesk(color: C.white)),
          backgroundColor: C.card,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('export failed: $e', style: GoogleFonts.spaceGrotesk(color: C.error))),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final bloc = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        bloc.add(ImportBackup(path));
        messenger.showSnackBar(
          SnackBar(
            content: Text('settings successfully imported', style: GoogleFonts.spaceGrotesk(color: C.white)),
            backgroundColor: C.card,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('import failed: $e', style: GoogleFonts.spaceGrotesk(color: C.error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── PROVIDERS ────────────────────────────────────────────────────
        const _Section('[PROVIDERS]'),
        if (state.providers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('>_ no providers configured',
                style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 12)),
          ),
        ...state.providers.map((p) => _ProviderRow(
              provider: p,
              isActive: state.activeProvider?.id == p.id,
            )),
        _AddBtn(label: '+ add provider', onTap: () => _showForm(context)),

        // ── APPEARANCE ───────────────────────────────────────────────────
        const _Section('[APPEARANCE]'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('theme preset',
                  style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _ThemePresetPicker(currentPreset: state.themePreset),
            ],
          ),
        ),

        // ── PREFERENCES ──────────────────────────────────────────────────
        const _Section('[PREFERENCES]'),
        _ToggleRow(
          label: 'streaming responses',
          sub: 'tokens appear as they generate',
          value: state.streamingEnabled,
          onChanged: (v) => context.read<SettingsBloc>().add(ToggleStreaming(v)),
        ),
        const _Divider(),
        _ToggleRow(
          label: 'sound effects',
          sub: 'audio feedback on send / receive',
          value: state.soundEnabled,
          onChanged: (v) => context.read<SettingsBloc>().add(ToggleSound(v)),
        ),

        // ── BACKUP & DATA ───────────────────────────────────────────────
        const _Section('[BACKUP & DATA]'),
        _BackupRow(
          label: 'export settings',
          sub: 'backup provider configurations to a local JSON file',
          actionLabel: 'export',
          onTap: () => _exportBackup(context),
        ),
        const _Divider(),
        _BackupRow(
          label: 'import settings',
          sub: 'restore configurations from a JSON backup file',
          actionLabel: 'import',
          onTap: () => _importBackup(context),
        ),

        // ── ABOUT ────────────────────────────────────────────────────────
        const _Section('[ABOUT]'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AXON v${AppConstants.appVersion}',
                  style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(AppConstants.appTagline,
                  style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Theme preset picker ───────────────────────────────────────────────────────

class _ThemePresetPicker extends StatelessWidget {
  final String currentPreset;
  const _ThemePresetPicker({required this.currentPreset});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: C.presets.entries.map((entry) {
        final preset = entry.value;
        final isSelected = currentPreset == entry.key;
        return GestureDetector(
          onTap: () {
            C.applyPreset(entry.key);
            context.read<SettingsBloc>().add(ChangeThemePreset(entry.key));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: preset.bg,
              border: Border.all(
                color: isSelected ? preset.accent : C.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color strip showing accent
                Container(
                  height: 3,
                  color: preset.accent,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Text(
                  preset.name,
                  style: GoogleFonts.jetBrainsMono(
                    color: isSelected ? preset.accent : const Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Mini preview dots
                Row(
                  children: [
                    Container(width: 6, height: 6, color: preset.accent),
                    const SizedBox(width: 3),
                    Container(width: 6, height: 6, color: preset.border),
                    const SizedBox(width: 3),
                    Container(width: 6, height: 6, color: preset.surface),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Provider row ─────────────────────────────────────────────────────────────

class _ProviderRow extends StatelessWidget {
  final AiProvider provider;
  final bool isActive;
  const _ProviderRow({required this.provider, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? C.surface : Colors.transparent,
        border: Border(left: BorderSide(color: isActive ? C.accent : C.border, width: isActive ? 2 : 1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(provider.name,
                              style: GoogleFonts.spaceGrotesk(
                                  color: C.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: C.accentDim,
                              child: Text('active',
                                  style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${provider.model} · ${provider.baseUrl}',
                          style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _SmallBtn(label: 'edit', onTap: () => _showForm(context, provider: provider)),
                const SizedBox(width: 6),
                _SmallBtn(
                  label: 'del',
                  danger: true,
                  onTap: () => context.read<SettingsBloc>().add(DeleteProvider(provider.id)),
                ),
              ],
            ),
          ),
          if (!isActive)
            GestureDetector(
              onTap: () => context.read<SettingsBloc>().add(SetActiveProvider(provider.id)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: C.border))),
                child: Text('set as active',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SmallBtn({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: danger ? C.error.withOpacity(0.4) : C.border)),
        child: Text(label,
            style: GoogleFonts.spaceGrotesk(color: danger ? C.error : C.grey1, fontSize: 12)),
      ),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: C.border)),
        child: Center(
          child: Text(label,
              style: GoogleFonts.spaceGrotesk(color: C.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: C.border))),
      child: Text(label,
          style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: C.accentText,
            activeTrackColor: C.accent,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(color: C.border, height: 1, indent: 20);
}

// ── Provider Form ─────────────────────────────────────────────────────────────

void _showForm(BuildContext context, {AiProvider? provider}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: _ProviderForm(provider: provider),
    ),
  );
}

class _ProviderForm extends StatefulWidget {
  final AiProvider? provider;
  const _ProviderForm({this.provider});

  @override
  State<_ProviderForm> createState() => _ProviderFormState();
}

class _ProviderFormState extends State<_ProviderForm> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _key = TextEditingController();
  final _model = TextEditingController();
  ProviderType _type = ProviderType.openai;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      final p = widget.provider!;
      _name.text = p.name;
      _url.text = p.baseUrl;
      _key.text = p.apiKey;
      _model.text = p.model;
      _type = p.type;
    } else {
      _applyDefaults(ProviderType.openai);
    }
  }

  void _applyDefaults(ProviderType t) {
    setState(() => _type = t);
    switch (t) {
      case ProviderType.openai:
        _name.text = 'OpenAI';
        _url.text = AppConstants.openAiBaseUrl;
        _model.text = AppConstants.defaultOpenAiModel;
      case ProviderType.gemini:
        _name.text = 'Gemini';
        _url.text = AppConstants.geminiBaseUrl;
        _model.text = AppConstants.defaultGeminiModel;
      case ProviderType.openRouter:
        _name.text = 'OpenRouter';
        _url.text = AppConstants.openRouterBaseUrl;
        _model.text = AppConstants.defaultOpenRouterModel;
      case ProviderType.lmStudio:
        _name.text = 'LM Studio';
        _url.text = AppConstants.lmStudioBaseUrl;
        _model.text = 'local-model';
      case ProviderType.custom:
        _name.text = 'Custom';
        _url.text = '';
        _model.text = '';
    }
  }

  void _save() {
    if (_name.text.isEmpty || _url.text.isEmpty || _model.text.isEmpty) return;
    final p = AiProvider(
      id: widget.provider?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      type: _type,
      baseUrl: _url.text.trim(),
      apiKey: _key.text.trim(),
      model: _model.text.trim(),
      createdAt: widget.provider?.createdAt ?? DateTime.now(),
    );
    if (widget.provider != null) {
      context.read<SettingsBloc>().add(UpdateProvider(p));
    } else {
      context.read<SettingsBloc>().add(AddProvider(p));
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 32, height: 2, color: C.border, margin: const EdgeInsets.only(bottom: 24))),
            Text(widget.provider != null ? '[EDIT PROVIDER]' : '[ADD PROVIDER]',
                style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 20),
            Text('type', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ProviderType.values
                    .map((t) => GestureDetector(
                          onTap: () => _applyDefaults(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _type == t ? C.accent : Colors.transparent,
                              border: Border.all(color: _type == t ? C.accent : C.border),
                            ),
                            child: Text(t.name,
                                style: GoogleFonts.spaceGrotesk(
                                    color: _type == t ? C.accentText : C.grey1,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _Field(label: 'name', ctrl: _name),
            const SizedBox(height: 10),
            _Field(label: 'base url', ctrl: _url, hint: 'https://api.openai.com/v1'),
            const SizedBox(height: 10),
            _Field(
              label: 'api key',
              ctrl: _key,
              hint: 'sk-...',
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(height: 10),
            _Field(label: 'model', ctrl: _model, hint: 'gpt-4o-mini'),
            const SizedBox(height: 20),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                final testing = state is SettingsLoaded && state.isTestingConnection;
                final result = state is SettingsLoaded ? state.connectionTestResult : null;
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: testing
                            ? null
                            : () {
                                final p = AiProvider(
                                  id: 'test',
                                  name: _name.text,
                                  type: _type,
                                  baseUrl: _url.text,
                                  apiKey: _key.text,
                                  model: _model.text,
                                  createdAt: DateTime.now(),
                                );
                                context.read<SettingsBloc>().add(TestProviderConnection(p));
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(border: Border.all(color: C.border)),
                          child: Center(
                            child: testing
                                ? SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: C.accent),
                                  )
                                : Text(
                                    result == null
                                        ? 'test connection'
                                        : result
                                            ? '✓ connected'
                                            : '✗ failed',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: result == null
                                          ? C.grey1
                                          : result
                                              ? C.success
                                              : C.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          color: C.accent,
                          child: Center(
                            child: Text(
                              widget.provider != null ? 'update' : 'add',
                              style: GoogleFonts.spaceGrotesk(
                                  color: C.accentText, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _Field({required this.label, required this.ctrl, this.hint, this.obscure = false, this.onToggleObscure});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: C.grey2,
                        size: 16),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _BackupRow extends StatelessWidget {
  final String label;
  final String sub;
  final String actionLabel;
  final VoidCallback onTap;

  const _BackupRow({required this.label, required this.sub, required this.actionLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: C.border)),
              child: Text(
                actionLabel,
                style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
