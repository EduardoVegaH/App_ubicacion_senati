import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';

class FriendsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Buscar estudiante por ID (solo devuelve el resultado específico)
  Future<Friend?> searchStudentById(String studentId) async {
    try {
      final querySnapshot = await _db
          .collection('usuarios')
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

      // Asegurar que esté en la lista de amigos
      await addFriend(doc.id);

      return Friend.fromFirestore(data, doc.id);
    } catch (e) {
      print('Error buscando estudiante: $e');
      return null;
    }
  }

  // Agregar amigo a la lista (si no existe)
  Future<bool> addFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // No permitir agregarse a sí mismo
      if (currentUser.uid == friendUid) return false;

      final userRef = _db.collection('usuarios').doc(currentUser.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      List<dynamic> friends = userDoc.data()?['amigos'] ?? [];
      
      // Verificar si ya es amigo
      if (friends.contains(friendUid)) {
        return true; // Ya es amigo, no hay problema
      }

      friends.add(friendUid);
      await userRef.update({'amigos': friends});
      return true;
    } catch (e) {
      print('Error agregando amigo: $e');
      return false;
    }
  }

  // Inicializar lista de amigos con todos los usuarios
  Future<void> initializeFriendsList() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userRef = _db.collection('usuarios').doc(currentUser.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;

      List<dynamic> existingFriends = userDoc.data()?['amigos'] ?? [];
      
      // Obtener todos los usuarios excepto el actual
      final allUsersSnapshot = await _db.collection('usuarios').get();
      List<String> allUserUids = allUsersSnapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) => doc.id)
          .toList();

      // Si la lista de amigos está vacía o no incluye todos los usuarios, actualizarla
      if (existingFriends.isEmpty || existingFriends.length != allUserUids.length) {
        // Combinar amigos existentes con nuevos usuarios
        Set<String> combinedFriends = Set<String>.from(existingFriends);
        combinedFriends.addAll(allUserUids);
        
        await userRef.update({'amigos': combinedFriends.toList()});
      }
    } catch (e) {
      print('Error inicializando lista de amigos: $e');
    }
  }

  // Obtener lista de amigos (solo los que están en la lista del usuario)
  Future<List<Friend>> getFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final userDoc = await _db.collection('usuarios').doc(currentUser.uid).get();
      if (!userDoc.exists) return [];

      List<dynamic> friendUids = userDoc.data()?['amigos'] ?? [];
      
      // Si la lista está vacía, inicializar con todos los usuarios
      if (friendUids.isEmpty) {
        await initializeFriendsList();
        // Volver a obtener después de inicializar
        final updatedDoc = await _db.collection('usuarios').doc(currentUser.uid).get();
        friendUids = updatedDoc.data()?['amigos'] ?? [];
      }

      if (friendUids.isEmpty) return [];

      List<Friend> friends = [];
      
      for (var uid in friendUids) {
        try {
          final friendDoc = await _db.collection('usuarios').doc(uid).get();
          if (friendDoc.exists) {
            final data = friendDoc.data()!;
            // Verificar que tenga los campos necesarios
            if (data.containsKey('IdEstudiante') && data.containsKey('NameEstudent')) {
              final friend = Friend.fromFirestore(data, uid);
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

  // Eliminar amigo
  Future<bool> removeFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userRef = _db.collection('usuarios').doc(currentUser.uid);
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

  // Escuchar cambios en tiempo real de un amigo
  Stream<Friend?> listenToFriend(String friendUid) {
    return _db
        .collection('usuarios')
        .doc(friendUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return Friend.fromFirestore(snapshot.data()!, friendUid);
    });
  }
}

