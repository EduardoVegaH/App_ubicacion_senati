import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Fuente de datos remota para amigos
class FriendsRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Buscar estudiante por ID
  Future<FriendModel?> searchStudentById(String studentId) async {
    try {
      final querySnapshot = await _db
          .collection(AppConstants.usersCollection)
          .where('IdEstudiante', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      // No permitir agregarse a sí mismo
      final currentUser = _auth.currentUser;
      if (currentUser != null && doc.id == currentUser.uid) {
        return null;
      }

      return FriendModel.fromFirestore(data, doc.id);
    } catch (e) {
      print('Error buscando estudiante: $e');
      return null;
    }
  }

  /// Buscar estudiante por nombre
  Future<List<FriendModel>> searchStudentByName(String name) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _db
          .collection(AppConstants.usersCollection)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final searchName = name.toLowerCase().trim();
      final results = <FriendModel>[];

      for (var doc in querySnapshot.docs) {
        // No permitir agregarse a sí mismo
        if (currentUser.uid == doc.id) continue;

        final data = doc.data();
        final studentName = (data['NameEstudent'] ?? '').toString().toLowerCase();

        // Buscar coincidencias parciales en el nombre
        if (studentName.contains(searchName)) {
          results.add(FriendModel.fromFirestore(data, doc.id));
        }
      }

      return results;
    } catch (e) {
      print('Error buscando estudiante por nombre: $e');
      return [];
    }
  }

  /// Verificar si un usuario ya es amigo
  Future<bool> isFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return false;

      final friends = userDoc.data()?['amigos'] as List<dynamic>? ?? [];
      return friends.contains(friendUid);
    } catch (e) {
      print('Error verificando si es amigo: $e');
      return false;
    }
  }

  /// Agregar amigo a la lista
  Future<bool> addFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      if (currentUser.uid == friendUid) return false;

      final userRef = _db.collection(AppConstants.usersCollection).doc(currentUser.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      List<dynamic> friends = userDoc.data()?['amigos'] ?? [];
      
      if (friends.contains(friendUid)) {
        return true;
      }

      friends.add(friendUid);
      await userRef.update({'amigos': friends});
      return true;
    } catch (e) {
      print('Error agregando amigo: $e');
      return false;
    }
  }

  /// Inicializar lista de amigos
  Future<void> initializeFriendsList() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userRef = _db.collection(AppConstants.usersCollection).doc(currentUser.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;

      List<dynamic> existingFriends = userDoc.data()?['amigos'] ?? [];
      
      final allUsersSnapshot = await _db.collection(AppConstants.usersCollection).get();
      List<String> allUserUids = allUsersSnapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) => doc.id)
          .toList();

      if (existingFriends.isEmpty || existingFriends.length != allUserUids.length) {
        Set<String> combinedFriends = Set<String>.from(existingFriends);
        combinedFriends.addAll(allUserUids);
        
        await userRef.update({'amigos': combinedFriends.toList()});
      }
    } catch (e) {
      print('Error inicializando lista de amigos: $e');
    }
  }

  /// Obtener lista de amigos
  Future<List<FriendModel>> getFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final userDoc = await _db.collection(AppConstants.usersCollection).doc(currentUser.uid).get();
      if (!userDoc.exists) return [];

      List<dynamic> friendUids = userDoc.data()?['amigos'] ?? [];
      
      if (friendUids.isEmpty) {
        await initializeFriendsList();
        final updatedDoc = await _db.collection(AppConstants.usersCollection).doc(currentUser.uid).get();
        friendUids = updatedDoc.data()?['amigos'] ?? [];
      }

      if (friendUids.isEmpty) return [];

      List<FriendModel> friends = [];
      
      for (var uid in friendUids) {
        try {
          final friendDoc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
          if (friendDoc.exists) {
            final data = friendDoc.data()!;
            if (data.containsKey('IdEstudiante') && data.containsKey('NameEstudent')) {
              final friend = FriendModel.fromFirestore(data, uid);
              friends.add(friend);
            }
          }
        } catch (e) {
          print('Error obteniendo amigo $uid: $e');
        }
      }

      return friends;
    } catch (e) {
      print('Error obteniendo amigos: $e');
      return [];
    }
  }

  /// Eliminar amigo
  Future<bool> removeFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userRef = _db.collection(AppConstants.usersCollection).doc(currentUser.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      List<dynamic> friends = userDoc.data()?['amigos'] ?? [];
      friends.remove(friendUid);
      
      await userRef.update({'amigos': friends});
      return true;
    } catch (e) {
      print('Error eliminando amigo: $e');
      return false;
    }
  }

  /// Escuchar cambios en tiempo real de un amigo
  Stream<FriendModel?> listenToFriend(String friendUid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(friendUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return FriendModel.fromFirestore(snapshot.data()!, friendUid);
    });
  }
}

