import '../repositories/home_repository.dart';

/// Use case para cerrar sesión
class LogoutUseCase {
  final HomeRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> call() async {
    return await _repository.logout();
  }
}

