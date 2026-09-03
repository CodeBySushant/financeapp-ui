import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.answer,
    required this.flagged,
    this.grounding,
  });

  final String conversationId;
  final String answer;
  final bool flagged;
  final Map<String, dynamic>? grounding;
}

class AssistantRepository {
  AssistantRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<AssistantStatus> status() async {
    final json = await _api.get<Map<String, dynamic>>('/api/ai/status');
    return AssistantStatus.fromJson(json);
  }

  Future<ChatReply> ask(String question, {String? conversationId}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/ai/chat',
      body: {
        'question': question.trim(),
        if (conversationId != null) 'conversationId': conversationId,
      },
    );
    return ChatReply(
      conversationId: J.str(data['conversationId']),
      answer: J.str(data['answer']),
      flagged: data['flagged'] as bool? ?? false,
      grounding: data['grounding'] is Map
          ? Map<String, dynamic>.from(data['grounding'] as Map)
          : null,
    );
  }

  Future<List<ChatMessage>> history(String conversationId) async {
    final data = await _api
        .get<Map<String, dynamic>>('/api/ai/conversations/$conversationId');
    final messages = data['messages'];
    if (messages is! List) return const [];
    return messages
        .whereType<Map>()
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<void> deleteConversation(String id) =>
      _api.delete<void>('/api/ai/conversations/$id');
}
