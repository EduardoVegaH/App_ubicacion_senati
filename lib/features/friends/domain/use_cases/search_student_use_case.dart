import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

/// Caso de uso para buscar estudiante por ID
class SearchStudentUseCase {
  final FriendsRepository _repository;
  
  SearchStudentUseCase(this._repository);
  
  Future<FriendEntity?> call(String studentId) async {
    return await _repository.searchStudentById(studentId);
  }
}

