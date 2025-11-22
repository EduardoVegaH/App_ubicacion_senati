import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../models/student_model.dart';

/// Fuente de datos remota para home
class HomeRemoteDataSource {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getUserData() async {
    return await _firebaseService.getUserData();
  }

  /// Actualizar ubicación del usuario
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String campusStatus,
  }) async {
    await _db.collection('usuarios').doc(userId).update({
      'lat': latitude,
      'lon': longitude,
      'estado': campusStatus,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _firebaseService.logout();
  }
}

