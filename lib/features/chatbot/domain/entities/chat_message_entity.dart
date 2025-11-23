/// Entidad de mensaje de chat (sin dependencias externas)
class ChatMessageEntity {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

