import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:axon/presentation/blocs/conversation/conversation_event.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String>? onRename;
  final int index;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    this.onRename,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final time = _fmt(conversation.updatedAt);
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: C.errorDim,
        child: Text('[DELETE]', style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 12)),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected ? C.surface : Colors.transparent,
            border: Border(
              left: BorderSide(color: isSelected ? C.accent : Colors.transparent, width: 2),
              bottom: BorderSide(color: C.border),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(time, style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (conversation.isPinned) ...[
                          Icon(Icons.push_pin_rounded, size: 10, color: C.accent),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              color: isSelected ? C.white : (conversation.isUnread ? C.white : C.grey1),
                              fontSize: 14,
                              fontWeight: isSelected || conversation.isUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (conversation.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: C.accent, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    if (conversation.lastMessagePreview != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        conversation.lastMessagePreview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: conversation.isUnread ? C.white.withOpacity(0.7) : C.grey2,
                          fontSize: 12,
                          fontWeight: conversation.isUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                    if (conversation.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: conversation.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: C.border),
                          ),
                          child: Text(
                            t.toLowerCase(),
                            style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 9),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: isSelected ? C.accent : C.grey2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
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
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ContextItem(
              icon: conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              label: conversation.isPinned ? 'unpin conversation' : 'pin conversation',
              onTap: () {
                Navigator.pop(sheetCtx);
                context.read<ConversationBloc>().add(TogglePinConversation(conversation.id));
              },
            ),
            const SizedBox(height: 6),
            _ContextItem(
              icon: Icons.label_outline_rounded,
              label: 'manage tags',
              onTap: () {
                Navigator.pop(sheetCtx);
                _showTagsDialog(context);
              },
            ),
            const SizedBox(height: 6),
            _ContextItem(
              icon: Icons.edit_outlined,
              label: 'rename',
              onTap: () {
                Navigator.pop(sheetCtx);
                _showRenameDialog(context);
              },
            ),
            const SizedBox(height: 6),
            _ContextItem(
              icon: Icons.delete_outline_rounded,
              label: 'delete',
              danger: true,
              onTap: () {
                Navigator.pop(sheetCtx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTagsDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final bloc = context.read<ConversationBloc>();
    // Local mutable copy for dialog state (entity tags are immutable)
    final localTags = List<String>.from(conversation.tags);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: C.card,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: C.border)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('[MANAGE TAGS]',
                    style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                if (localTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: localTags.map((t) => Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                      color: C.surface,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.toLowerCase(), style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 12)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              bloc.add(RemoveConversationTag(conversation.id, t));
                              setDialogState(() => localTags.remove(t));
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: C.error),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: ctrl,
                  style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'add tag (e.g. work, math)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () {
                        final val = ctrl.text.trim().toLowerCase();
                        if (val.isNotEmpty && !localTags.contains(val)) {
                          bloc.add(AddConversationTag(conversation.id, val));
                          setDialogState(() => localTags.add(val));
                          ctrl.clear();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(dialogCtx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: C.accent,
                    child: Text('done',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                            color: C.accentText, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: conversation.title);
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
              Text('[RENAME]',
                  style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'conversation title',
                  hintStyle: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                        final newTitle = ctrl.text.trim();
                        if (newTitle.isNotEmpty) {
                          onRename?.call(newTitle);
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: C.accent,
                        child: Text('rename',
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

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return 'yest';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
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
            Text('[CONFIRM DELETE]',
                style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 14),
            Text(
              'Delete "${conversation.title}"? This cannot be undone.',
              style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: C.border)),
                      child: Text('cancel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: C.errorDim,
                      child: Text('delete',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                              color: C.error, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContextItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ContextItem({
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
