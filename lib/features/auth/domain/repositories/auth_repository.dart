import '../entities/user_entity.dart';

/// Interfaz del repositorio de autenticación
abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String semester,
  });
  Future<void> logout();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> getAuthStateChanges();
}

