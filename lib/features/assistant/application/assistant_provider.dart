import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/assistant_repository.dart';
import '../domain/chat_message.dart';

final assistantRepositoryProvider =
    Provider<AssistantRepository>((ref) => AssistantRepository());

/// Whether the assistant is configured server-side at all. Read once so the
/// entry point can be hidden rather than failing when tapped.
final assistantStatusProvider = FutureProvider<AssistantStatus>(
  (ref) => ref.read(assistantRepositoryProvider).status(),
);

class ChatState {
  const ChatState({
    this.messages = const [],
    this.conversationId,
    this.sending = false,
    this.error,
    this.premiumRequired = false,
  });

  final List<ChatMessage> messages;
  final String? conversationId;
  final bool sending;
  final String? error;

  /// `POST /api/ai/chat` is gated behind requirePremium, so a free account gets
  /// a 402. That is an upsell, not a failure, and is shown differently.
  final bool premiumRequired;

  ChatState copyWith({
    List<ChatMessage>? messages,
    Object? conversationId = _unset,
    bool? sending,
    Object? error = _unset,
    bool? premiumRequired,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        conversationId: identical(conversationId, _unset)
            ? this.conversationId
            : conversationId as String?,
        sending: sending ?? this.sending,
        error: identical(error, _unset) ? this.error : error as String?,
        premiumRequired: premiumRequired ?? this.premiumRequired,
      );

  static const _unset = Object();
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repo) : super(const ChatState());

  final AssistantRepository _repo;
  int _localId = 0;

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.length < 3 || state.sending) return;

    // The question appears immediately; only the answer waits on the network.
    final mine = ChatMessage(
      id: 'local-${_localId++}',
      role: ChatRole.user,
      content: text,
    );

    state = state.copyWith(
      messages: [...state.messages, mine],
      sending: true,
      error: null,
      premiumRequired: false,
    );

    try {
      final reply = await _repo.ask(text, conversationId: state.conversationId);
      state = state.copyWith(
        conversationId: reply.conversationId,
        sending: false,
        messages: [
          ...state.messages,
          ChatMessage(
            id: 'reply-${_localId++}',
            role: ChatRole.assistant,
            content: reply.answer,
            flagged: reply.flagged,
            grounding: reply.grounding,
          ),
        ],
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        sending: false,
        premiumRequired: e.code == ApiErrorCode.premiumRequired,
        error: e.code == ApiErrorCode.premiumRequired ? null : e.message,
        // The question stays on screen so it can be retried without retyping.
      );
    }
  }

  void clear() => state = const ChatState();
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) {
  return ChatController(ref.read(assistantRepositoryProvider));
});
