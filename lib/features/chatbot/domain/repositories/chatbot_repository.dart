/// Interfaz del repositorio de chatbot
abstract class ChatbotRepository {
  Future<String> sendMessage(String message);
  void resetChat();
  void updateStudentData(Map<String, dynamic>? studentData);
}

