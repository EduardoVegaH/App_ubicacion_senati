import 'dart:async';
import '../../domain/entities/friend_entity.dart';
import '../../domain/repositories/friends_repository.dart';
import '../data_sources/friends_remote_data_source.dart';

/// Implementación del repositorio de amigos
class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource _dataSource;
  
  FriendsRepositoryImpl(this._dataSource);
  
  @override
  Future<FriendEntity?> searchStudentById(String studentId) async {
    final model = await _dataSource.searchStudentById(studentId);
    return model?.toEntity();
  }

  @override
  Future<List<FriendEntity>> searchStudentByName(String name) async {
    final models = await _dataSource.searchStudentByName(name);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> isFriend(String friendUid) async {
    return await _dataSource.isFriend(friendUid);
  }
  
  @override
  Future<bool> addFriend(String friendUid) async {
    return await _dataSource.addFriend(friendUid);
  }
  
  @override
  Future<void> initializeFriendsList() async {
    return await _dataSource.initializeFriendsList();
  }
  
  @override
  Future<List<FriendEntity>> getFriends() async {
    final models = await _dataSource.getFriends();
    return models.map((m) => m.toEntity()).toList();
  }
  
  @override
  Future<bool> removeFriend(String friendUid) async {
    return await _dataSource.removeFriend(friendUid);
  }
  
  @override
  Stream<FriendEntity?> listenToFriend(String friendUid) {
    return _dataSource.listenToFriend(friendUid).map((model) => model?.toEntity());
  }
}

