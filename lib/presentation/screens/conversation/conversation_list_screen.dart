import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axon/core/di/service_locator.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/presentation/blocs/chat/chat_bloc.dart';
import 'package:axon/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:axon/presentation/blocs/conversation/conversation_event.dart';
import 'package:axon/presentation/blocs/conversation/conversation_state.dart';
import 'package:axon/presentation/blocs/settings/settings_bloc.dart';
import 'package:axon/presentation/blocs/settings/settings_state.dart';
import 'package:axon/presentation/screens/chat/chat_screen.dart';
import 'package:axon/presentation/screens/settings/settings_screen.dart';
import 'package:axon/presentation/widgets/conversation/conversation_tile.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String _selectedTag = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _open(BuildContext context, String id, String title) {
    final bloc = context.read<ConversationBloc>();
    bloc.add(MarkConversationAsRead(id));
    bloc.add(SelectConversation(id));
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BlocProvider(
          create: (_) => sl<ChatBloc>(),
          child: ChatScreen(conversationId: id, conversationTitle: title),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    ).then((_) => bloc.add(const RefreshConversations()));
  }

  void _newChat(BuildContext context) async {
    final bloc = context.read<ConversationBloc>();
    final navigator = Navigator.of(context);
    bloc.add(const CreateConversation());
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final state = bloc.state;
    if (state is ConversationLoaded && state.conversations.isNotEmpty) {
      final newest = state.conversations.first;
      bloc.add(MarkConversationAsRead(newest.id));
      bloc.add(SelectConversation(newest.id));
      navigator.push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => BlocProvider(
            create: (_) => sl<ChatBloc>(),
            child: ChatScreen(conversationId: newest.id, conversationTitle: newest.title),
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 220),
        ),
      ).then((_) => bloc.add(const RefreshConversations()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onSearch: () => setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  context.read<ConversationBloc>().add(const ClearSearch());
                }
              }),
              onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              onNew: () => _newChat(context),
              searching: _searching,
            ),
            if (_searching)
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (q) {
                  if (q.isEmpty) {
                    context.read<ConversationBloc>().add(const ClearSearch());
                  } else {
                    context.read<ConversationBloc>().add(SearchConversations(q));
                  }
                },
              ),
            const _StatusBar(),
            Expanded(
              child: BlocConsumer<ConversationBloc, ConversationState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is ConversationLoading || state is ConversationCreating) {
                    return const _LoadingView();
                  }
                  if (state is ConversationEmpty) {
                    return _EmptyView(onNew: () => _newChat(context));
                  }
                  if (state is ConversationError) {
                    return _ErrorView(message: state.message);
                  }
                  if (state is ConversationLoaded) {
                    if (state.conversations.isEmpty) {
                      return _EmptyView(onNew: () => _newChat(context));
                    }

                    // Gather unique tags
                    final allTags = <String>{};
                    for (final c in state.conversations) {
                      allTags.addAll(c.tags);
                    }

                    // Filter list by selected tag
                    List<Conversation> filtered = state.conversations;
                    if (_selectedTag == 'Pinned') {
                      filtered = filtered.where((c) => c.isPinned).toList();
                    } else if (_selectedTag != 'All') {
                      filtered = filtered.where((c) => c.tags.contains(_selectedTag)).toList();
                    }

                    return Column(
                      children: [
                        _TagFiltersBar(
                          selectedTag: _selectedTag,
                          tags: allTags,
                          onSelected: (t) => setState(() => _selectedTag = t),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    '>_ no conversations in "$_selectedTag"',
                                    style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, i) {
                                    final conv = filtered[i];
                                    return ConversationTile(
                                      conversation: conv,
                                      isSelected: state.selectedConversationId == conv.id,
                                      index: i,
                                      onTap: () => _open(context, conv.id, conv.title),
                                      onDelete: () => context.read<ConversationBloc>().add(DeleteConversation(conv.id)),
                                      onRename: (newTitle) => context.read<ConversationBloc>().add(UpdateConversationTitle(conv.id, newTitle)),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  }
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

class _Header extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onNew;
  final bool searching;

  const _Header({required this.onSearch, required this.onSettings, required this.onNew, required this.searching});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AXON',
                  style: GoogleFonts.spaceGrotesk(
                      color: C.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (_, state) {
                  if (state is SettingsLoaded && state.activeProvider != null) {
                    return Text(
                      '${state.activeProvider!.displayName} / ${state.activeProvider!.model}',
                      style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11),
                    );
                  }
                  return Text('>_ no provider configured',
                      style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 11));
                },
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(icon: searching ? Icons.search_off_rounded : Icons.search_rounded, onTap: onSearch),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.settings_rounded, onTap: onSettings),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: C.accent,
              child: Text('+ new', style: GoogleFonts.spaceGrotesk(color: C.accentText, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(border: Border.fromBorderSide(BorderSide(color: C.border))),
        child: Icon(icon, color: C.grey1, size: 18),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '>_ search conversations',
          prefixIcon: const Icon(Icons.search_rounded, color: C.grey2, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          filled: true,
          fillColor: C.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.accent)),
          hintStyle: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 12),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (_, state) {
        final count = state is ConversationLoaded ? state.conversations.length : 0;
        final searching = state is ConversationLoaded && state.isSearching;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
          child: Row(
            children: [
              Text(
                searching ? 'search results' : '$count conversation${count == 1 ? '' : 's'}',
                style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1, color: C.accent)),
          const SizedBox(height: 16),
          Text('loading_', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyView({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AXON', style: GoogleFonts.spaceGrotesk(color: C.border, fontSize: 64, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('>_ no conversations yet', style: GoogleFonts.jetBrainsMono(color: C.grey2, fontSize: 13)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: C.accent,
              child: Text('+ start new conversation',
                  style: GoogleFonts.spaceGrotesk(color: C.accentText, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('[ERROR] $message', style: GoogleFonts.jetBrainsMono(color: C.error, fontSize: 13)),
    );
  }
}

class _TagFiltersBar extends StatelessWidget {
  final String selectedTag;
  final Set<String> tags;
  final ValueChanged<String> onSelected;

  const _TagFiltersBar({
    required this.selectedTag,
    required this.tags,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final list = ['All', 'Pinned', ...tags];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          final isSel = selectedTag == t;
          IconData? icon;
          if (t == 'Pinned') icon = Icons.push_pin_rounded;
          if (t == 'All') icon = Icons.chat_bubble_outline_rounded;
          
          return GestureDetector(
            onTap: () => onSelected(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? C.accentDim : Colors.transparent,
                border: Border.all(color: isSel ? C.accent : C.border),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 12, color: isSel ? C.accent : C.grey1),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(Icons.folder_open_rounded, size: 12, color: isSel ? C.accent : C.grey1),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    t.toLowerCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: isSel ? C.accent : C.grey1,
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
