import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para registrar usuario
class RegisterUseCase {
  final AuthRepository _repository;
  
  RegisterUseCase(this._repository);
  
  Future<UserEntity?> call({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String semester,
  }) async {
    return await _repository.register(
      email: email,
      password: password,
      name: name,
      studentId: studentId,
      semester: semester,
    );
  }
}

