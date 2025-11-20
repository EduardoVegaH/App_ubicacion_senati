import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService{
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  //Obtener los datos del usuario autenticado
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if(user == null) return null;

    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if(doc.exists){
      return doc.data();
    } else {
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }
}