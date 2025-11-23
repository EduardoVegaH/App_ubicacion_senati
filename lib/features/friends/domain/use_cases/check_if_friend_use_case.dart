import '../repositories/friends_repository.dart';

/// Caso de uso para verificar si un usuario ya es amigo
class CheckIfFriendUseCase {
  final FriendsRepository _repository;
  
  CheckIfFriendUseCase(this._repository);
  
  Future<bool> call(String friendUid) async {
    return await _repository.isFriend(friendUid);
  }
}

