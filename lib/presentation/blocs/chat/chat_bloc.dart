import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:axon/domain/entities/message.dart';
import 'package:axon/domain/repositories/ai_repository.dart';
import 'package:axon/domain/repositories/conversation_repository.dart';
import 'package:axon/domain/repositories/settings_repository.dart';
import 'package:axon/core/errors/exceptions.dart';
import 'package:axon/presentation/blocs/chat/chat_event.dart';
import 'package:axon/presentation/blocs/chat/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AiRepository _aiRepository;
  final ConversationRepository _conversationRepository;
  final SettingsRepository _settingsRepository;
  final _uuid = const Uuid();
  Timer? _backoffTimer;

  // Per-conversation context (not in state - no need to trigger rebuilds)
  String? _currentConversationId;
  String? _lastUserMessageContent;
  List<String>? _lastUserMessageAttachments;
  String? _modelOverride;
  String? _systemPrompt;

  ChatBloc({
    required AiRepository aiRepository,
    required ConversationRepository conversationRepository,
    required SettingsRepository settingsRepository,
  })  : _aiRepository = aiRepository,
        _conversationRepository = conversationRepository,
        _settingsRepository = settingsRepository,
        super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<SendMessageStream>(_onSendMessageStream);
    on<StreamTokenReceived>(_onStreamTokenReceived);
    on<StreamCompleted>(_onStreamCompleted);
    on<StreamError>(_onStreamError);
    on<RetryLastMessage>(_onRetry);
    on<ClearChat>(_onClear);
    on<DeleteMessage>(_onDeleteMessage);
    on<ChangeConversationModel>(_onChangeModel);
    on<UpdateSystemPrompt>(_onUpdateSystemPrompt);
    on<EditMessage>(_onEditMessage);
    on<RetryCountdownTick>(_onRetryCountdownTick);
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    _backoffTimer?.cancel();
    _currentConversationId = event.conversationId;
    emit(const ChatLoading());
    try {
      final results = await Future.wait([
        _conversationRepository.getMessages(event.conversationId),
        _settingsRepository.getConversationModel(event.conversationId),
        _settingsRepository.getSystemPrompt(event.conversationId),
      ]);
      _modelOverride = results[1] as String?;
      _systemPrompt = results[2] as String?;
      emit(ChatLoaded(
        messages: results[0] as List<Message>,
        conversationId: event.conversationId,
        modelOverride: _modelOverride,
        systemPrompt: _systemPrompt,
      ));
    } catch (e) {
      emit(ChatError(
        messages: const [],
        conversationId: event.conversationId,
        error: 'Failed to load messages: $e',
        canRetry: false,
      ));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (_isProcessing()) return;
    _backoffTimer?.cancel();
    final provider = await _settingsRepository.getActiveProvider();
    if (provider == null) { emit(const ChatProviderNotConfigured()); return; }

    final effectiveProvider = _modelOverride != null
        ? provider.copyWith(model: _modelOverride)
        : provider;

    final currentMessages = _getCurrentMessages();
    _lastUserMessageContent = event.content;
    _lastUserMessageAttachments = event.attachmentPaths;

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: event.conversationId,
      role: MessageRole.user,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachmentPaths: event.attachmentPaths,
    );

    final messagesWithUser = [...currentMessages, userMessage];
    await _conversationRepository.saveMessage(userMessage);
    emit(ChatSending(messages: messagesWithUser, conversationId: event.conversationId));

    try {
      final sendMessages = _prependSystemPrompt(messagesWithUser);
      final response = await _aiRepository.sendMessage(
          messages: sendMessages, provider: effectiveProvider);

      final assistantMessage = Message(
        id: _uuid.v4(),
        conversationId: event.conversationId,
        role: MessageRole.assistant,
        content: response.content,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        tokenCount: response.tokenCount ?? (response.content.length ~/ 4),
      );
      await _conversationRepository.saveMessage(assistantMessage);
      final finalMessages = [...messagesWithUser, assistantMessage];
      emit(ChatSuccess(
        messages: finalMessages,
        conversationId: event.conversationId,
        lastAssistantMessage: assistantMessage,
        modelOverride: _modelOverride,
        systemPrompt: _systemPrompt,
      ));
    } catch (e) {
      final isRateLimit = e is RateLimitException;
      final errorMsg = _errorMessage(e);
      emit(ChatError(
        messages: messagesWithUser,
        conversationId: event.conversationId,
        error: errorMsg,
        canRetry: true,
        retrySeconds: isRateLimit ? 10 : 0,
      ));
      if (isRateLimit) {
        _startRateLimitCountdown(messagesWithUser, event.conversationId, errorMsg);
      }
    }
  }

  Future<void> _onSendMessageStream(SendMessageStream event, Emitter<ChatState> emit) async {
    if (_isProcessing()) return;
    _backoffTimer?.cancel();
    final provider = await _settingsRepository.getActiveProvider();
    if (provider == null) { emit(const ChatProviderNotConfigured()); return; }

    final effectiveProvider = _modelOverride != null
        ? provider.copyWith(model: _modelOverride)
        : provider;

    final currentMessages = _getCurrentMessages();
    _lastUserMessageContent = event.content;
    _lastUserMessageAttachments = event.attachmentPaths;

    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: event.conversationId,
      role: MessageRole.user,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachmentPaths: event.attachmentPaths,
    );

    final messagesWithUser = [...currentMessages, userMessage];
    await _conversationRepository.saveMessage(userMessage);
    final streamingId = _uuid.v4();

    emit(ChatStreaming(
      messages: messagesWithUser,
      conversationId: event.conversationId,
      streamingContent: '',
      streamingMessageId: streamingId,
    ));

    final buffer = StringBuffer();
    final sendMessages = _prependSystemPrompt(messagesWithUser);

    try {
      await emit.forEach<String>(
        _aiRepository.sendMessageStream(messages: sendMessages, provider: effectiveProvider),
        onData: (token) {
          buffer.write(token);
          return ChatStreaming(
            messages: messagesWithUser,
            conversationId: event.conversationId,
            streamingContent: buffer.toString(),
            streamingMessageId: streamingId,
          );
        },
        onError: (error, _) {
          return ChatError(
            messages: messagesWithUser,
            conversationId: event.conversationId,
            error: _errorMessage(error),
            canRetry: true,
          );
        },
      );

      if (state is ChatStreaming && buffer.isNotEmpty) {
        final contentText = buffer.toString();
        final assistantMessage = Message(
          id: streamingId,
          conversationId: event.conversationId,
          role: MessageRole.assistant,
          content: contentText,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          tokenCount: contentText.length ~/ 4, // Rough estimation for stream tokens
        );
        await _conversationRepository.saveMessage(assistantMessage);
        final finalMessages = [...messagesWithUser, assistantMessage];
        emit(ChatSuccess(
          messages: finalMessages,
          conversationId: event.conversationId,
          lastAssistantMessage: assistantMessage,
          modelOverride: _modelOverride,
          systemPrompt: _systemPrompt,
        ));
      }
    } catch (error) {
      final isRateLimit = error is RateLimitException;
      final errorMsg = _errorMessage(error);
      emit(ChatError(
        messages: messagesWithUser,
        conversationId: event.conversationId,
        error: errorMsg,
        canRetry: true,
        retrySeconds: isRateLimit ? 10 : 0,
      ));
      if (isRateLimit) {
        _startRateLimitCountdown(messagesWithUser, event.conversationId, errorMsg);
      }
    }
  }

  void _startRateLimitCountdown(List<Message> messages, String conversationId, String errorMsg) {
    _backoffTimer?.cancel();
    _backoffTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSeconds = 10 - timer.tick;
      if (currentSeconds <= 0) {
        timer.cancel();
        add(const RetryLastMessage());
      } else {
        add(RetryCountdownTick(
          messages: messages,
          conversationId: conversationId,
          error: errorMsg,
          seconds: currentSeconds,
        ));
      }
    });
  }

  void _onRetryCountdownTick(RetryCountdownTick event, Emitter<ChatState> emit) {
    emit(ChatError(
      messages: event.messages,
      conversationId: event.conversationId,
      error: event.error,
      canRetry: true,
      retrySeconds: event.seconds,
    ));
  }

  void _onStreamTokenReceived(StreamTokenReceived event, Emitter<ChatState> emit) {
    if (state is ChatStreaming) {
      final s = state as ChatStreaming;
      emit(s.copyWith(streamingContent: s.streamingContent + event.token));
    }
  }

  void _onStreamCompleted(StreamCompleted event, Emitter<ChatState> emit) {}

  void _onStreamError(StreamError event, Emitter<ChatState> emit) {
    final current = state;
    final messages = current is ChatStreaming ? current.messages : _getCurrentMessages();
    emit(ChatError(
      messages: messages,
      conversationId: _currentConversationId ?? '',
      error: event.error,
      canRetry: true,
    ));
  }

  Future<void> _onRetry(RetryLastMessage event, Emitter<ChatState> emit) async {
    if (_lastUserMessageContent == null || _currentConversationId == null) return;
    final streaming = await _settingsRepository.getStreamingEnabled();
    if (streaming) {
      add(SendMessageStream(
        content: _lastUserMessageContent!,
        conversationId: _currentConversationId!,
        attachmentPaths: _lastUserMessageAttachments,
      ));
    } else {
      add(SendMessage(
        content: _lastUserMessageContent!,
        conversationId: _currentConversationId!,
        attachmentPaths: _lastUserMessageAttachments,
      ));
    }
  }

  void _onClear(ClearChat event, Emitter<ChatState> emit) => emit(const ChatInitial());

  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    final messages = _getCurrentMessages();
    try {
      await _conversationRepository.deleteMessage(event.messageId);
      final updated = messages.where((m) => m.id != event.messageId).toList();
      emit(ChatLoaded(
        messages: updated,
        conversationId: _currentConversationId ?? '',
        modelOverride: _modelOverride,
        systemPrompt: _systemPrompt,
      ));
    } catch (_) {}
  }

  Future<void> _onChangeModel(ChangeConversationModel event, Emitter<ChatState> emit) async {
    _modelOverride = event.model;
    if (_currentConversationId != null) {
      await _settingsRepository.setConversationModel(_currentConversationId!, event.model);
    }
    // Refresh loaded state with new model
    final messages = _getCurrentMessages();
    if (messages.isNotEmpty || state is ChatLoaded) {
      emit(ChatLoaded(
        messages: messages,
        conversationId: _currentConversationId ?? '',
        modelOverride: _modelOverride,
        systemPrompt: _systemPrompt,
      ));
    }
  }

  Future<void> _onUpdateSystemPrompt(UpdateSystemPrompt event, Emitter<ChatState> emit) async {
    _systemPrompt = event.prompt.isEmpty ? null : event.prompt;
    if (_currentConversationId != null) {
      await _settingsRepository.setSystemPrompt(_currentConversationId!, event.prompt);
    }
    final messages = _getCurrentMessages();
    emit(ChatLoaded(
      messages: messages,
      conversationId: _currentConversationId ?? '',
      modelOverride: _modelOverride,
      systemPrompt: _systemPrompt,
    ));
  }

  Future<void> _onEditMessage(EditMessage event, Emitter<ChatState> emit) async {
    if (_isProcessing() || _currentConversationId == null) return;
    _backoffTimer?.cancel();
    try {
      final messages = _getCurrentMessages();
      final targetIdx = messages.indexWhere((m) => m.id == event.messageId);
      if (targetIdx == -1) return;

      // Delete all messages after the user message from database
      for (int i = targetIdx + 1; i < messages.length; i++) {
        await _conversationRepository.deleteMessage(messages[i].id);
      }

      // Update the user message text in database and set isEdited = true
      final oldMsg = messages[targetIdx];
      final updatedMsg = oldMsg.copyWith(
        content: event.newContent,
        isEdited: true,
        timestamp: DateTime.now(),
      );
      await _conversationRepository.saveMessage(updatedMsg);

      // Truncate messages list in memory
      final truncatedList = [...messages.sublist(0, targetIdx), updatedMsg];
      emit(ChatLoaded(
        messages: truncatedList,
        conversationId: _currentConversationId!,
        modelOverride: _modelOverride,
        systemPrompt: _systemPrompt,
      ));

      // Re-trigger sending
      final streaming = await _settingsRepository.getStreamingEnabled();
      if (streaming) {
        add(SendMessageStream(
          content: event.newContent,
          conversationId: _currentConversationId!,
          attachmentPaths: updatedMsg.attachmentPaths,
        ));
      } else {
        add(SendMessage(
          content: event.newContent,
          conversationId: _currentConversationId!,
          attachmentPaths: updatedMsg.attachmentPaths,
        ));
      }
    } catch (_) {}
  }

  List<Message> _prependSystemPrompt(List<Message> messages) {
    if (_systemPrompt == null || _systemPrompt!.isEmpty) return messages;
    final systemMsg = Message(
      id: 'system_$_currentConversationId',
      conversationId: _currentConversationId ?? '',
      role: MessageRole.system,
      content: _systemPrompt!,
      timestamp: DateTime.now(),
    );
    return [systemMsg, ...messages];
  }

  bool _isProcessing() => state is ChatSending || state is ChatStreaming;

  List<Message> _getCurrentMessages() {
    final s = state;
    if (s is ChatLoaded) return s.messages;
    if (s is ChatSending) return s.messages;
    if (s is ChatStreaming) return s.messages;
    if (s is ChatSuccess) return s.messages;
    if (s is ChatError) return s.messages;
    return const [];
  }

  String _errorMessage(Object error) {
    if (error is AuthException) return error.message;
    if (error is RateLimitException) return error.message;
    if (error is TimeoutException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is ServerException) return error.message;
    if (error is InvalidResponseException) return error.message;
    if (error is AppException) return error.message;
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Future<void> close() {
    _backoffTimer?.cancel();
    return super.close();
  }
}
