import '../../domain/repositories/chatbot_repository.dart';
import '../data_sources/chatbot_remote_data_source.dart';

/// Implementación del repositorio de chatbot
class ChatbotRepositoryImpl implements ChatbotRepository {
  final ChatbotRemoteDataSource _dataSource;
  
  ChatbotRepositoryImpl(this._dataSource);
  
  @override
  Future<String> sendMessage(String message) async {
    return await _dataSource.sendMessage(message);
  }
  
  @override
  void resetChat() {
    _dataSource.resetChat();
  }
  
  @override
  void updateStudentData(Map<String, dynamic>? studentData) {
    _dataSource.updateStudentData(studentData);
  }
}

