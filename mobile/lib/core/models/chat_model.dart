class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.topic,
    required this.createdAt,
  });

  final String id;
  final String role; // "user" | "assistant"
  final String content;
  final String? topic;
  final String createdAt;

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        topic: j['topic'] as String?,
        createdAt: j['created_at'] as String,
      );
}
