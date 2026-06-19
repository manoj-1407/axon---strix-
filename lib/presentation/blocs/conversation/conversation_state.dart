import 'package:equatable/equatable.dart';
import 'package:axon/domain/entities/conversation.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationLoaded extends ConversationState {
  final List<Conversation> conversations;
  final String? selectedConversationId;
  final bool isSearching;
  final String searchQuery;

  const ConversationLoaded({
    required this.conversations,
    this.selectedConversationId,
    this.isSearching = false,
    this.searchQuery = '',
  });

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    String? selectedConversationId,
    bool? isSearching,
    String? searchQuery,
    bool clearSelection = false,
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationId: clearSelection
          ? null
          : selectedConversationId ?? this.selectedConversationId,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [conversations, selectedConversationId, isSearching, searchQuery];
}

class ConversationEmpty extends ConversationState {
  const ConversationEmpty();
}

class ConversationError extends ConversationState {
  final String message;
  const ConversationError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConversationCreating extends ConversationState {
  final List<Conversation> conversations;
  const ConversationCreating(this.conversations);

  @override
  List<Object?> get props => [conversations];
}
