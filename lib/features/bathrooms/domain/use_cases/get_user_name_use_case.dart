import 'package:firebase_auth/firebase_auth.dart';

/// Use case para obtener el nombre del usuario actual
class GetUserNameUseCase {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> call() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.displayName ?? user.email ?? 'Usuario';
  }
}

