import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

/// Caso de uso para buscar estudiante por nombre
class SearchStudentByNameUseCase {
  final FriendsRepository _repository;
  
  SearchStudentByNameUseCase(this._repository);
  
  Future<List<FriendEntity>> call(String name) async {
    return await _repository.searchStudentByName(name);
  }
}

