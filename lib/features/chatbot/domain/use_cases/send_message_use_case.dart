import '../repositories/chatbot_repository.dart';

/// Caso de uso para enviar mensaje al chatbot
class SendMessageUseCase {
  final ChatbotRepository _repository;
  
  SendMessageUseCase(this._repository);
  
  Future<String> call(String message) async {
    return await _repository.sendMessage(message);
  }
}

