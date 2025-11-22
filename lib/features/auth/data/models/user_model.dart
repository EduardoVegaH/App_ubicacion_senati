import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Modelo de datos de usuario (con serialización)
class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.email,
    super.name,
    super.studentId,
    super.semester,
  });
  
  /// Crear desde Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
    );
  }
  
  /// Crear desde Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? data['NameEstudent'],
      studentId: data['studentId'] ?? data['IdEstudiante'],
      semester: data['semester'],
    );
  }
  
  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      if (name != null) 'name': name,
      if (studentId != null) 'studentId': studentId,
      if (semester != null) 'semester': semester,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Convertir a entidad
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      studentId: studentId,
      semester: semester,
    );
  }
}

