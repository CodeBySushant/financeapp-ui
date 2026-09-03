import 'package:flutter/foundation.dart';

import '../../../core/models/json.dart';

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.flagged = false,
    this.grounding,
    this.pending = false,
  });

  final String id;
  final ChatRole role;
  final String content;

  /// The server sets this when it could not trace every figure in the answer
  /// back to the user's own records, and replaces the answer with a refusal.
  /// The UI marks it so nobody mistakes a refusal for a result.
  final bool flagged;

  /// The facts the answer was built from, so the claim can be audited.
  final Map<String, dynamic>? grounding;

  /// A locally-added message still in flight.
  final bool pending;

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: J.str(j['id']),
        role: (j['role'] as String?) == 'USER' ? ChatRole.user : ChatRole.assistant,
        content: J.str(j['content']),
        flagged: j['flagged'] as bool? ?? false,
        grounding: j['groundingJson'] is Map
            ? Map<String, dynamic>.from(j['groundingJson'] as Map)
            : null,
      );
}

@immutable
class AssistantStatus {
  const AssistantStatus({required this.available, this.provider});

  final bool available;
  final String? provider;

  factory AssistantStatus.fromJson(Map<String, dynamic> j) => AssistantStatus(
        available: j['available'] as bool? ?? false,
        provider: j['provider'] as String?,
      );
}
