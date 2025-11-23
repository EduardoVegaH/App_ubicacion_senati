import 'dart:async';
import '../entities/friend_entity.dart';

/// Interfaz del repositorio de amigos
abstract class FriendsRepository {
  Future<FriendEntity?> searchStudentById(String studentId);
  Future<List<FriendEntity>> searchStudentByName(String name);
  Future<bool> isFriend(String friendUid);
  Future<bool> addFriend(String friendUid);
  Future<void> initializeFriendsList();
  Future<List<FriendEntity>> getFriends();
  Future<bool> removeFriend(String friendUid);
  Stream<FriendEntity?> listenToFriend(String friendUid);
}

