import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

/// Caso de uso para obtener lista de amigos
class GetFriendsUseCase {
  final FriendsRepository _repository;
  
  GetFriendsUseCase(this._repository);
  
  Future<List<FriendEntity>> call() async {
    return await _repository.getFriends();
  }
}

