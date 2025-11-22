import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
class LogoutUseCase {
  final AuthRepository _repository;
  
  LogoutUseCase(this._repository);
  
  Future<void> call() async {
    return await _repository.logout();
  }
}

