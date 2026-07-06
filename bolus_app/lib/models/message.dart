import 'profile.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageText;
  final DateTime? createdAt;
  final Profile? sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json, {Profile? sender}) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      sender: sender ?? (json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_text': messageText,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
