import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión
class LoginUseCase {
  final AuthRepository _repository;
  
  LoginUseCase(this._repository);
  
  Future<UserEntity?> call(String email, String password) async {
    return await _repository.login(email, password);
  }
}

