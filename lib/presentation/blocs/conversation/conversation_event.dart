import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationEvent {
  const LoadConversations();
}

class CreateConversation extends ConversationEvent {
  final String title;
  const CreateConversation({this.title = ''});

  @override
  List<Object?> get props => [title];
}

class DeleteConversation extends ConversationEvent {
  final String conversationId;
  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SelectConversation extends ConversationEvent {
  final String conversationId;
  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class UpdateConversationTitle extends ConversationEvent {
  final String conversationId;
  final String newTitle;
  const UpdateConversationTitle(this.conversationId, this.newTitle);

  @override
  List<Object?> get props => [conversationId, newTitle];
}

class SearchConversations extends ConversationEvent {
  final String query;
  const SearchConversations(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends ConversationEvent {
  const ClearSearch();
}

class RefreshConversations extends ConversationEvent {
  const RefreshConversations();
}

class TogglePinConversation extends ConversationEvent {
  final String conversationId;
  const TogglePinConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MarkConversationAsRead extends ConversationEvent {
  final String conversationId;
  const MarkConversationAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class AddConversationTag extends ConversationEvent {
  final String conversationId;
  final String tag;
  const AddConversationTag(this.conversationId, this.tag);

  @override
  List<Object?> get props => [conversationId, tag];
}

class RemoveConversationTag extends ConversationEvent {
  final String conversationId;
  final String tag;
  const RemoveConversationTag(this.conversationId, this.tag);

  @override
  List<Object?> get props => [conversationId, tag];
}
