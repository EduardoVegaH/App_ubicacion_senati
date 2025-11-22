/// Clase base para errores de la aplicación
abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Error del servidor
class ServerFailure extends Failure {
  ServerFailure(String message, {String? code}) : super(message, code: code);
}

/// Error de red
class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(message);
}

/// Error de no encontrado
class NotFoundFailure extends Failure {
  NotFoundFailure(String message) : super(message);
}

/// Error de permisos
class PermissionFailure extends Failure {
  PermissionFailure(String message) : super(message);
}

/// Error de validación
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

/// Error desconocido
class UnknownFailure extends Failure {
  UnknownFailure(String message) : super(message);
}

