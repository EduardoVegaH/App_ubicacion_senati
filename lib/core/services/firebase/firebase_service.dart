import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio base de Firebase
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _db;
  
  /// Obtener el usuario actual
  User? get currentUser => _auth.currentUser;
  
  /// Verificar si hay un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;
  
  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (doc.exists) {
      return doc.data();
    } else {
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}

