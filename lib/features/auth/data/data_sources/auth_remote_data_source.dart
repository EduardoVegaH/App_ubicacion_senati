import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Fuente de datos remota para autenticación
class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  /// Iniciar sesión
  Future<UserModel?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user == null) return null;
      
      return UserModel.fromFirebaseUser(cred.user!);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Registrar usuario
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String semester,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user == null) return null;
      
      final uid = cred.user!.uid;
      
      // Guardar datos en Firestore
      await _db.collection(AppConstants.studentsCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'studentId': studentId,
        'semester': semester,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return UserModel.fromFirebaseUser(cred.user!);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
  
  /// Obtener usuario actual
  UserModel? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }
  
  /// Stream de cambios de autenticación
  Stream<UserModel?> getAuthStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }
}

