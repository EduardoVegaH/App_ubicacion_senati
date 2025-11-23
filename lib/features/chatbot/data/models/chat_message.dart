import '../../domain/entities/chat_message_entity.dart';

/// Modelo de mensaje de chat
class ChatMessage extends ChatMessageEntity {
  ChatMessage({
    required super.text,
    required super.isUser,
    required super.timestamp,
  });
}

