import '../repositories/chatbot_repository.dart';

/// Use case para resetear el chat
class ResetChatUseCase {
  final ChatbotRepository _repository;

  ResetChatUseCase(this._repository);

  void call() {
    _repository.resetChat();
  }
}

