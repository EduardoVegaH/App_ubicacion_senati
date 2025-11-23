import '../repositories/friends_repository.dart';

/// Use case para eliminar un amigo
class RemoveFriendUseCase {
  final FriendsRepository _repository;

  RemoveFriendUseCase(this._repository);

  /// Eliminar un amigo de la lista
  Future<bool> call(String friendUid) async {
    return await _repository.removeFriend(friendUid);
  }
}

