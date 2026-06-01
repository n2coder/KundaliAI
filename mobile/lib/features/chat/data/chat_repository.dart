import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/chat_model.dart';

class ChatRepository {
  const ChatRepository(this._dio);
  final Dio _dio;

  Future<ChatMessageModel> sendMessage(
    String content, {
    String? topic,
  }) async {
    final resp = await _dio.post(
      ApiEndpoints.chatMessage,
      data: {
        'content': content,
        if (topic != null) 'topic': topic,
      },
    );
    final body = resp.data as Map<String, dynamic>;
    return ChatMessageModel.fromJson(body['reply'] as Map<String, dynamic>);
  }

  Future<List<ChatMessageModel>> getHistory() async {
    final resp = await _dio.get(ApiEndpoints.chatHistory);
    return (resp.data as List<dynamic>)
        .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
