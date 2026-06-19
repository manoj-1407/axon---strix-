import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:axon/domain/entities/conversation.dart';
import 'package:axon/domain/repositories/conversation_repository.dart';
import 'package:axon/presentation/blocs/conversation/conversation_event.dart';
import 'package:axon/presentation/blocs/conversation/conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository _repository;
  StreamSubscription<List<Conversation>>? _conversationSub;

  ConversationBloc(this._repository) : super(const ConversationLoading()) {
    on<LoadConversations>(_onLoad);
    on<CreateConversation>(_onCreate);
    on<DeleteConversation>(_onDelete);
    on<SelectConversation>(_onSelect);
    on<UpdateConversationTitle>(_onUpdateTitle);
    on<SearchConversations>(_onSearch);
    on<ClearSearch>(_onClearSearch);
    on<RefreshConversations>(_onRefresh);
    on<TogglePinConversation>(_onTogglePin);
    on<MarkConversationAsRead>(_onMarkAsRead);
    on<AddConversationTag>(_onAddTag);
    on<RemoveConversationTag>(_onRemoveTag);

    add(const LoadConversations());
  }

  Future<void> _onLoad(
      LoadConversations event, Emitter<ConversationState> emit) async {
    emit(const ConversationLoading());
    try {
      final conversations = await _repository.getAllConversations();
      if (conversations.isEmpty) {
        emit(const ConversationEmpty());
      } else {
        emit(ConversationLoaded(conversations: conversations));
      }
    } catch (e) {
      emit(ConversationError('Failed to load conversations: $e'));
    }
  }

  Future<void> _onCreate(
      CreateConversation event, Emitter<ConversationState> emit) async {
    final current = state;
    final currentConvs = current is ConversationLoaded
        ? current.conversations
        : const <Conversation>[];

    emit(ConversationCreating(currentConvs));

    try {
      final conversation = await _repository.createConversation(event.title);
      final updated = [conversation, ...currentConvs];
      emit(ConversationLoaded(
        conversations: updated,
        selectedConversationId: conversation.id,
      ));
    } catch (e) {
      emit(ConversationError('Failed to create conversation: $e'));
    }
  }

  Future<void> _onDelete(
      DeleteConversation event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;

    try {
      await _repository.deleteConversation(event.conversationId);
      final updated = current.conversations
          .where((c) => c.id != event.conversationId)
          .toList();

      if (updated.isEmpty) {
        emit(const ConversationEmpty());
      } else {
        final newSelectedId =
            current.selectedConversationId == event.conversationId
                ? null
                : current.selectedConversationId;
        emit(current.copyWith(
          conversations: updated,
          selectedConversationId: newSelectedId,
        ));
      }
    } catch (e) {
      emit(ConversationError('Failed to delete conversation: $e'));
    }
  }

  void _onSelect(
      SelectConversation event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final current = state as ConversationLoaded;
      emit(current.copyWith(
          selectedConversationId: event.conversationId));
    }
  }

  Future<void> _onUpdateTitle(
      UpdateConversationTitle event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;

    try {
      final conv =
          current.conversations.firstWhere((c) => c.id == event.conversationId);
      final updated = conv.copyWith(
          title: event.newTitle, updatedAt: DateTime.now());
      await _repository.updateConversation(updated);

      final updatedList = current.conversations
          .map((c) => c.id == event.conversationId ? updated : c)
          .toList();
      emit(current.copyWith(conversations: updatedList));
    } catch (e) {
      emit(ConversationError('Failed to update title: $e'));
    }
  }

  Future<void> _onSearch(
      SearchConversations event, Emitter<ConversationState> emit) async {
    if (event.query.isEmpty) {
      add(const ClearSearch());
      return;
    }
    try {
      final results = await _repository.searchConversations(event.query);
      emit(ConversationLoaded(
        conversations: results,
        isSearching: true,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(ConversationError('Search failed: $e'));
    }
  }

  Future<void> _onClearSearch(
      ClearSearch event, Emitter<ConversationState> emit) async {
    final convs = await _repository.getAllConversations();
    if (convs.isEmpty) {
      emit(const ConversationEmpty());
    } else {
      emit(ConversationLoaded(conversations: convs));
    }
  }

  Future<void> _onRefresh(
      RefreshConversations event, Emitter<ConversationState> emit) async {
    try {
      final conversations = await _repository.getAllConversations();
      if (conversations.isEmpty) {
        emit(const ConversationEmpty());
      } else {
        final current =
            state is ConversationLoaded ? state as ConversationLoaded : null;
        emit(ConversationLoaded(
          conversations: conversations,
          selectedConversationId: current?.selectedConversationId,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onTogglePin(
      TogglePinConversation event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;
    try {
      final conv = current.conversations.firstWhere((c) => c.id == event.conversationId);
      final updated = conv.copyWith(isPinned: !conv.isPinned);
      await _repository.updateConversation(updated);
      
      final updatedList = await _repository.getAllConversations();
      emit(current.copyWith(conversations: updatedList));
    } catch (_) {}
  }

  Future<void> _onMarkAsRead(
      MarkConversationAsRead event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;
    try {
      final conv = current.conversations.firstWhere((c) => c.id == event.conversationId);
      if (conv.isUnread) {
        final updated = conv.copyWith(isUnread: false);
        await _repository.updateConversation(updated);
        final updatedList = await _repository.getAllConversations();
        emit(current.copyWith(conversations: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onAddTag(
      AddConversationTag event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;
    try {
      final conv = current.conversations.firstWhere((c) => c.id == event.conversationId);
      if (!conv.tags.contains(event.tag)) {
        final updated = conv.copyWith(tags: [...conv.tags, event.tag]);
        await _repository.updateConversation(updated);
        final updatedList = await _repository.getAllConversations();
        emit(current.copyWith(conversations: updatedList));
      }
    } catch (_) {}
  }

  Future<void> _onRemoveTag(
      RemoveConversationTag event, Emitter<ConversationState> emit) async {
    if (state is! ConversationLoaded) return;
    final current = state as ConversationLoaded;
    try {
      final conv = current.conversations.firstWhere((c) => c.id == event.conversationId);
      if (conv.tags.contains(event.tag)) {
        final updated = conv.copyWith(tags: conv.tags.where((t) => t != event.tag).toList());
        await _repository.updateConversation(updated);
        final updatedList = await _repository.getAllConversations();
        emit(current.copyWith(conversations: updatedList));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _conversationSub?.cancel();
    return super.close();
  }
}
