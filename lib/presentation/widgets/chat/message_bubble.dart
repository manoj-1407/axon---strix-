import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/presentation/blocs/chat/chat_bloc.dart';
import 'package:axon/presentation/blocs/chat/chat_event.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) return _UserMessage(message: message);
    return _AssistantMessage(message: message);
  }
}

class _UserMessage extends StatelessWidget {
  final Message message;
  const _UserMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.timestamp);
    return GestureDetector(
      onLongPress: () => _showUserMessageContextMenu(context, message),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.attachmentPaths != null && message.attachmentPaths!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: message.attachmentPaths!.map((path) {
                          final file = File(path);
                          if (!file.existsSync()) return const SizedBox.shrink();
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              border: Border.all(color: C.border),
                            ),
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        }).toList(),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.card,
                      border: Border(right: BorderSide(color: C.accent, width: 2)),
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (message.isEdited) ...[
                        Text('(edited) · ', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 10)),
                      ],
                      Text(time, style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
                      const SizedBox(width: 6),
                      _statusIcon(message.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: C.accentDim,
              child: Icon(Icons.person_outline_rounded, size: 16, color: C.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(MessageStatus status) {
    if (status == MessageStatus.sending) {
      return SizedBox(
        width: 10, height: 10,
        child: CircularProgressIndicator(strokeWidth: 1, color: C.accent),
      );
    }
    if (status == MessageStatus.error) {
      return const Icon(Icons.error_outline_rounded, size: 12, color: C.error);
    }
    return const Icon(Icons.done_all_rounded, size: 12, color: C.grey2);
  }
}

class _AssistantMessage extends StatelessWidget {
  final Message message;
  const _AssistantMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.timestamp);

    if (message.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.errorDim,
            border: Border.all(color: C.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: C.error, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.errorMessage ?? 'Request failed.',
                  style: GoogleFonts.spaceGrotesk(color: C.error, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: C.surface,
            child: const Icon(Icons.terminal_rounded, size: 16, color: C.grey1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'axon',
                      style: GoogleFonts.jetBrainsMono(
                        color: C.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(time, style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 1),
                Container(width: double.infinity, height: 1, color: C.border, margin: const EdgeInsets.only(bottom: 10)),
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: _mdStyle(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, message.content),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: C.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 11, color: C.grey2),
                            const SizedBox(width: 4),
                            Text('copy', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    if (message.tokenCount != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${message.tokenCount} tokens',
                        style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _mdStyle() => MarkdownStyleSheet(
    p: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15, height: 1.7),
    h1: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 20, fontWeight: FontWeight.w700),
    h2: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 17, fontWeight: FontWeight.w700),
    h3: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 15, fontWeight: FontWeight.w600),
    code: GoogleFonts.jetBrainsMono(color: C.code, fontSize: 13, backgroundColor: C.surface),
    codeblockDecoration: BoxDecoration(
      color: C.surface,
      border: const Border(left: BorderSide(color: C.code, width: 2)),
    ),
    codeblockPadding: const EdgeInsets.all(16),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    blockquoteDecoration: const BoxDecoration(
      border: Border(left: BorderSide(color: C.grey2, width: 2)),
    ),
    strong: GoogleFonts.spaceGrotesk(color: C.white, fontWeight: FontWeight.w700, fontSize: 15),
    em: GoogleFonts.spaceGrotesk(color: C.grey1, fontStyle: FontStyle.italic, fontSize: 15),
    a: GoogleFonts.spaceGrotesk(color: C.accent, fontSize: 15),
    listBullet: GoogleFonts.spaceGrotesk(color: C.accent, fontSize: 15),
    tableHead: GoogleFonts.spaceGrotesk(color: C.white, fontWeight: FontWeight.w700, fontSize: 13),
    tableBody: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13),
    horizontalRuleDecoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
  );
}

void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('copied to clipboard', style: GoogleFonts.jetBrainsMono(color: C.white, fontSize: 13)),
      duration: const Duration(seconds: 2),
      backgroundColor: C.card,
    ),
  );
}

void _showUserMessageContextMenu(BuildContext context, Message message) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 32, height: 2, color: C.border, margin: const EdgeInsets.only(bottom: 20)),
          ),
          Text(
            'Message Options',
            style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _ContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'copy text',
            onTap: () {
              Navigator.pop(sheetCtx);
              _copyToClipboard(context, message.content);
            },
          ),
          const SizedBox(height: 6),
          _ContextMenuItem(
            icon: Icons.edit_outlined,
            label: 'edit message',
            onTap: () {
              Navigator.pop(sheetCtx);
              _showEditDialog(context, message);
            },
          ),
          const SizedBox(height: 6),
          _ContextMenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'delete message',
            danger: true,
            onTap: () {
              Navigator.pop(sheetCtx);
              context.read<ChatBloc>().add(DeleteMessage(message.id));
            },
          ),
        ],
      ),
    ),
  );
}

void _showEditDialog(BuildContext context, Message message) {
  final ctrl = TextEditingController(text: message.content);
  showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(border: Border.all(color: C.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[EDIT USER PROMPT]',
                style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: C.border)),
                      child: Text('cancel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final val = ctrl.text.trim();
                      if (val.isNotEmpty) {
                        context.read<ChatBloc>().add(EditMessage(messageId: message.id, newContent: val));
                      }
                      Navigator.pop(dialogCtx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: C.accent,
                      child: Text('regenerate',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                              color: C.accentText, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ).then((_) => ctrl.dispose());
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? C.error : C.grey1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: danger ? C.errorDim : C.border)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
