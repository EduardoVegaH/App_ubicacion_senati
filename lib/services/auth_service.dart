import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registrar usuario
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String semester,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );

    final uid = cred.user?.uid;

    await _db.collection('students').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'studentId': studentId,
      'semester': semester,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return cred.user;
  }

  // Iniciar sesión
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password,
    );

    return cred.user;
  }

  // Cerrar sesión
  Future<void> logout() async => await _auth.signOut;
}