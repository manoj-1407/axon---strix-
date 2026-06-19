import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/presentation/blocs/chat/chat_bloc.dart';
import 'package:axon/presentation/blocs/chat/chat_event.dart';
import 'package:axon/presentation/blocs/chat/chat_state.dart';
import 'package:axon/presentation/blocs/settings/settings_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_event.dart';
import 'package:axon/presentation/blocs/settings/settings_state.dart';
import 'package:axon/presentation/screens/settings/settings_screen.dart';
import 'package:axon/presentation/widgets/chat/chat_composer.dart';
import 'package:axon/presentation/widgets/chat/message_bubble.dart';
import 'package:axon/presentation/widgets/chat/typing_indicator.dart';
import 'package:axon/domain/entities/message.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ChatScreen({super.key, required this.conversationId, required this.conversationTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessages(widget.conversationId));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _send(String text, List<String> attachments, bool streaming) {
    if (streaming) {
      context.read<ChatBloc>().add(SendMessageStream(content: text, conversationId: widget.conversationId, attachmentPaths: attachments));
    } else {
      context.read<ChatBloc>().add(SendMessage(content: text, conversationId: widget.conversationId, attachmentPaths: attachments));
    }
    _scrollToBottom();
  }

  double _calculateSessionCost(List<Message> messages, String modelName) {
    double total = 0;
    for (final m in messages) {
      if (m.tokenCount != null) {
        final lower = modelName.toLowerCase();
        double rate = 0.15; // default gpt-4o-mini input rate per 1M tokens
        if (lower.contains('gpt-4o') && !lower.contains('mini')) {
          rate = m.isAssistant ? 15.00 : 5.00;
        } else if (lower.contains('pro')) {
          rate = m.isAssistant ? 5.00 : 1.25;
        } else if (lower.contains('flash')) {
          rate = m.isAssistant ? 0.30 : 0.075;
        } else {
          rate = m.isAssistant ? 0.60 : 0.15;
        }
        total += (m.tokenCount! / 1000000.0) * rate;
      }
    }
    return total;
  }

  int _calculateSessionTokens(List<Message> messages) {
    int total = 0;
    for (final m in messages) {
      if (m.tokenCount != null) {
        total += m.tokenCount!;
      }
    }
    return total;
  }

  void _showShortcutsHelp() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: C.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border.all(color: C.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[KEYBOARD SHORTCUTS]',
                  style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 20),
              const _ShortcutRow(keys: 'Ctrl + K', desc: 'Open model picker'),
              const SizedBox(height: 8),
              const _ShortcutRow(keys: 'Ctrl + /', desc: 'Show shortcuts list'),
              const SizedBox(height: 8),
              const _ShortcutRow(keys: 'Esc', desc: 'Back to conversations'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: C.accent,
                  child: Center(
                    child: Text('close',
                        style: GoogleFonts.spaceGrotesk(color: C.accentText, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
          if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
            // Trigger model picker click
            final chatState = context.read<ChatBloc>().state;
            final settingsState = context.read<SettingsBloc>().state;
            if (settingsState is SettingsLoaded && settingsState.activeProvider != null) {
              final modelOverride = chatState is ChatLoaded ? chatState.modelOverride
                  : chatState is ChatSuccess ? chatState.modelOverride : null;
              final displayModel = modelOverride ?? settingsState.activeProvider!.model;
              _showModelPicker(context, settingsState.activeProvider!, displayModel);
            }
          } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.slash) {
            _showShortcutsHelp();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Column(
            children: [
              _ChatHeader(
                conversationId: widget.conversationId,
                title: widget.conversationTitle,
                onShowShortcuts: _showShortcutsHelp,
              ),
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (_, state) {
                    if (state is ChatSuccess || state is ChatStreaming) _scrollToBottom();
                    if (state is ChatProviderNotConfigured) _showNoProvider(context);
                  },
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 1, color: C.accent),
                            ),
                            const SizedBox(height: 14),
                            Text('loading messages_', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 12)),
                          ],
                        ),
                      );
                    }

                    final messages = _msgs(state);
                    final isLoading = state is ChatSending || state is ChatStreaming;
                    final streamingContent = state is ChatStreaming ? state.streamingContent : null;
                    final hasError = state is ChatError;

                    if (messages.isEmpty && !isLoading) {
                      return _EmptyChat(title: widget.conversationTitle);
                    }

                    return BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, settingsState) {
                        final streaming = settingsState is SettingsLoaded ? settingsState.streamingEnabled : true;
                        final activeModel = (settingsState is SettingsLoaded && settingsState.activeProvider != null)
                            ? settingsState.activeProvider!.model
                            : 'unknown';
                        
                        final sessionCost = _calculateSessionCost(messages, activeModel);
                        final sessionTokens = _calculateSessionTokens(messages);

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                                itemCount: messages.length + (isLoading ? 1 : 0) + (hasError ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i < messages.length) return MessageBubble(message: messages[i]);
                                  if (state is ChatStreaming && streamingContent != null) {
                                    return _StreamingMessage(content: streamingContent);
                                  }
                                  if (isLoading) return const TypingIndicator();
                                  if (state is ChatError) {
                                    return _ErrorBar(
                                      error: state.error,
                                      canRetry: state.canRetry,
                                      retrySeconds: state.retrySeconds,
                                      onRetry: () => context.read<ChatBloc>().add(const RetryLastMessage()),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            // Cost / token stats footer
                            if (sessionTokens > 0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: C.border))),
                                color: C.surface,
                                child: Text(
                                  'Est. Cost: \$${sessionCost.toStringAsFixed(5)} · $sessionTokens tokens',
                                  style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 10),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ChatComposer(isLoading: isLoading, onSend: (t, atts) => _send(t, atts, streaming)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Message> _msgs(ChatState s) {
    if (s is ChatLoaded) return s.messages;
    if (s is ChatSending) return s.messages;
    if (s is ChatStreaming) return s.messages;
    if (s is ChatSuccess) return s.messages;
    if (s is ChatError) return s.messages;
    return [];
  }

  void _showNoProvider(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: C.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border.all(color: C.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[ERROR]', style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 12),
              Text('No AI provider configured.', style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15)),
              const SizedBox(height: 6),
              Text('Configure a provider in settings to start.',
                  style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: C.accent,
                  child: Center(
                    child: Text('open settings',
                        style: GoogleFonts.spaceGrotesk(
                            color: C.accentText, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, dynamic provider, String currentModel) {
    context.read<SettingsBloc>().add(FetchModels(provider));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: _ModelPickerSheet(
          currentModel: currentModel,
          defaultModel: provider.model,
          conversationId: widget.conversationId,
          chatBloc: context.read<ChatBloc>(),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String desc;
  const _ShortcutRow({required this.keys, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: C.surface,
          child: Text(keys, style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Text(desc, style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13)),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String conversationId;
  final String title;
  final VoidCallback onShowShortcuts;

  const _ChatHeader({required this.conversationId, required this.title, required this.onShowShortcuts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, chatState) {
                final modelOverride = chatState is ChatLoaded ? chatState.modelOverride
                    : chatState is ChatSuccess ? chatState.modelOverride : null;

                return BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settingsState) {
                    final provider = settingsState is SettingsLoaded ? settingsState.activeProvider : null;
                    final displayModel = modelOverride ?? provider?.model ?? 'no provider';
                    final activeProvider = (provider != null &&
                        chatState is! ChatSending &&
                        chatState is! ChatStreaming) ? provider : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                                color: C.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: activeProvider != null
                              ? () => _showModelPicker(context, activeProvider, displayModel)
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (modelOverride != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  color: C.accentDim,
                                  child: Text('custom',
                                      style: GoogleFonts.jetBrainsMono(
                                          color: C.accent, fontSize: 9, letterSpacing: 0.5)),
                                ),
                              Text(displayModel,
                                  style: GoogleFonts.jetBrainsMono(
                                      color: activeProvider != null ? C.accent : C.grey2, fontSize: 10)),
                              if (activeProvider != null) ...[
                                const SizedBox(width: 3),
                                Icon(Icons.expand_more_rounded, size: 12, color: C.accent),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Keyboard shortcuts button
          GestureDetector(
            onTap: onShowShortcuts,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(border: Border.all(color: C.border)),
              child: const Icon(Icons.keyboard_outlined, size: 18, color: C.grey1),
            ),
          ),
          // System prompt button
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final hasPrompt = state is ChatLoaded
                  ? (state.systemPrompt?.isNotEmpty ?? false)
                  : state is ChatSuccess ? (state.systemPrompt?.isNotEmpty ?? false) : false;
              final currentPrompt = state is ChatLoaded ? state.systemPrompt
                  : state is ChatSuccess ? state.systemPrompt : null;
              return GestureDetector(
                onTap: () => _showSystemPromptSheet(context, currentPrompt ?? ''),
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: hasPrompt ? C.accent : C.border),
                    color: hasPrompt ? C.accentDim : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: hasPrompt ? C.accent : C.grey1,
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(border: Border.all(color: C.border)),
              child: const Icon(Icons.tune_rounded, color: C.grey1, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelPicker(BuildContext context, dynamic provider, String currentModel) {
    context.read<SettingsBloc>().add(FetchModels(provider));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: _ModelPickerSheet(
          currentModel: currentModel,
          defaultModel: provider.model,
          conversationId: conversationId,
          chatBloc: context.read<ChatBloc>(),
        ),
      ),
    );
  }

  void _showSystemPromptSheet(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SystemPromptSheet(
        current: current,
        onSave: (prompt) => context.read<ChatBloc>().add(UpdateSystemPrompt(prompt)),
      ),
    );
  }
}

// ── Model Picker Sheet ────────────────────────────────────────────────────────

class ModelDetails {
  final String params;
  final String released;
  final String cost;
  const ModelDetails({required this.params, required this.released, required this.cost});
}

final modelMeta = <String, ModelDetails>{
  'gpt-4o-mini': const ModelDetails(params: '8B equiv', released: 'July 2024', cost: r'$0.15 / $0.60'),
  'gpt-4o': const ModelDetails(params: '175B equiv', released: 'May 2024', cost: r'$5.00 / $15.00'),
  'gemini-1.5-flash': const ModelDetails(params: '8B', released: 'May 2024', cost: r'$0.075 / $0.30'),
  'gemini-1.5-pro': const ModelDetails(params: '1.5T', released: 'May 2024', cost: r'$1.25 / $5.00'),
  'claude-3-5-sonnet': const ModelDetails(params: '200B equiv', released: 'June 2024', cost: r'$3.00 / $15.00'),
};

class _ModelPickerSheet extends StatelessWidget {
  final String currentModel;
  final String defaultModel;
  final String conversationId;
  final ChatBloc chatBloc;

  const _ModelPickerSheet({
    required this.currentModel,
    required this.defaultModel,
    required this.conversationId,
    required this.chatBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
            child: Row(
              children: [
                Text('[SELECT MODEL]',
                    style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: C.grey2, size: 18),
                ),
              ],
            ),
          ),
          Flexible(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                if (state is! SettingsLoaded) return const SizedBox.shrink();
                if (state.isFetchingModels) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: C.accent),
                          ),
                          const SizedBox(height: 12),
                          Text('fetching models_',
                              style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final models = state.availableModels.isNotEmpty
                    ? state.availableModels
                    : [defaultModel];

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  children: [
                    _ModelRow(
                      model: defaultModel,
                      label: '$defaultModel (default)',
                      isSelected: currentModel == defaultModel,
                      onTap: () {
                        chatBloc.add(const ChangeConversationModel(null));
                        Navigator.pop(context);
                      },
                    ),
                    if (models.isNotEmpty && models.first != defaultModel)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text('available models',
                            style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 10, letterSpacing: 1)),
                      ),
                    ...models.where((m) => m != defaultModel).map((model) => _ModelRow(
                          model: model,
                          isSelected: currentModel == model,
                          onTap: () {
                            chatBloc.add(ChangeConversationModel(model));
                            Navigator.pop(context);
                          },
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final String model;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelRow({required this.model, this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ModelDetails? details;
    for (final entry in modelMeta.entries) {
      if (model.toLowerCase().contains(entry.key)) {
        details = entry.value;
        break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? C.accentDim : Colors.transparent,
          border: Border(
            left: BorderSide(color: isSelected ? C.accent : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label ?? model,
                    style: GoogleFonts.jetBrainsMono(
                        color: isSelected ? C.accent : C.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Params: ${details.params} · Released: ${details.released} · Cost/1M: ${details.cost}',
                      style: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, size: 14, color: C.accent),
          ],
        ),
      ),
    );
  }
}

// ── System Prompt Sheet ───────────────────────────────────────────────────────

class _SystemPromptSheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;

  const _SystemPromptSheet({required this.current, required this.onSave});

  @override
  State<_SystemPromptSheet> createState() => _SystemPromptSheetState();
}

class _SystemPromptSheetState extends State<_SystemPromptSheet> {
  late final TextEditingController _ctrl;
  final List<Map<String, String>> _personas = [
    {
      'name': 'Code Reviewer',
      'prompt': 'You are an expert senior code reviewer. Review the provided code snippet for bug safety, design patterns, clean code principles, and performance. Be concise and point out lines of interest.'
    },
    {
      'name': 'Creative Writer',
      'prompt': 'You are an experienced creative copywriter and novelist. Help me write engaging stories, select metaphors, structure narrative arcs, and brainstorm creative paths.'
    },
    {
      'name': 'Bug Finder',
      'prompt': 'You are a meticulous debugger. Focus on spotting potential edge cases, null pointers, race conditions, memory leaks, and concurrency problems in the provided code.'
    },
    {
      'name': 'UI/UX Consultant',
      'prompt': 'You are a high-end UI/UX consultant. Review UI descriptions, suggest colors (HSL), typography (Space Grotesk), micro-interactions, layout padding, and components.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 32, height: 2, color: C.border, margin: const EdgeInsets.only(bottom: 20))),
          Row(
            children: [
              Text('[SYSTEM PROMPT]',
                  style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
              const Spacer(),
              if (_ctrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _ctrl.clear();
                    widget.onSave('');
                    Navigator.pop(context);
                  },
                  child: Text('clear',
                      style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Select a pre-built persona template or type custom prompt below:',
              style: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 12)),
          const SizedBox(height: 12),
          // Persona Quick-select chips
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _personas.length,
              itemBuilder: (context, i) {
                final item = _personas[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _ctrl.text = item['prompt']!;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: C.border),
                    ),
                    child: Center(
                      child: Text(
                        item['name']!.toLowerCase(),
                        style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'You are a helpful assistant focused on...',
              hintStyle: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              widget.onSave(_ctrl.text.trim());
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: C.accent,
              child: Center(
                child: Text('save prompt',
                    style: GoogleFonts.spaceGrotesk(
                        color: C.accentText, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String title;
  const _EmptyChat({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                    color: C.border, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('>_ send a message or a photo to begin',
                style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StreamingMessage extends StatelessWidget {
  final String content;
  const _StreamingMessage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('axon',
              style: GoogleFonts.jetBrainsMono(
                  color: C.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 1),
          Container(width: double.infinity, height: 1, color: C.border, margin: const EdgeInsets.only(bottom: 10)),
          Text(
            content.isEmpty ? ' ' : content,
            style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 8, height: 14, color: C.accent),
              const SizedBox(width: 8),
              Text('streaming', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final String error;
  final bool canRetry;
  final int retrySeconds;
  final VoidCallback onRetry;

  const _ErrorBar({required this.error, required this.canRetry, required this.retrySeconds, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final hasCountdown = retrySeconds > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.errorDim,
        border: Border.all(color: C.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('[ERROR]', style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 11)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasCountdown ? '$error (retrying in ${retrySeconds}s...)' : error,
              style: GoogleFonts.spaceGrotesk(color: C.error, fontSize: 13),
            ),
          ),
          if (canRetry && !hasCountdown)
            GestureDetector(
              onTap: onRetry,
              child: Text('retry',
                  style: GoogleFonts.jetBrainsMono(
                      color: C.error, fontSize: 12, decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }
}
