import 'chatbot_service.dart';

/// Fuente de datos remota para chatbot (usa el servicio existente)
class ChatbotRemoteDataSource {
  final ChatbotService _service;
  
  ChatbotRemoteDataSource() : _service = ChatbotService();
  
  Future<String> sendMessage(String message) async {
    return await _service.sendMessage(message);
  }
  
  void resetChat() {
    _service.resetChat();
  }
  
  void updateStudentData(Map<String, dynamic>? studentData) {
    _service.updateStudentData(studentData);
  }
  
  bool get isApiKeyConfigured => _service.isApiKeyConfigured;
}

