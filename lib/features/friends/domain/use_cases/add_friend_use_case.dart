import '../repositories/friends_repository.dart';

/// Caso de uso para agregar amigo
class AddFriendUseCase {
  final FriendsRepository _repository;
  
  AddFriendUseCase(this._repository);
  
  Future<bool> call(String friendUid) async {
    return await _repository.addFriend(friendUid);
  }
}

