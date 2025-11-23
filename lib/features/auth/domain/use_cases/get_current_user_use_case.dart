import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case para obtener el usuario actual autenticado
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Obtener el usuario actual
  /// Retorna null si no hay usuario autenticado
  UserEntity? call() {
    return _repository.getCurrentUser();
  }
}

