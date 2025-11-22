/// Mensajes de error estándar de la aplicación
class ExceptionMessages {
  // Errores de red
  static const String networkError = 'Error de conexión. Verifica tu internet.';
  static const String timeoutError = 'Tiempo de espera agotado. Intenta nuevamente.';
  
  // Errores de Firebase
  static const String firebaseError = 'Error al conectar con Firebase.';
  static const String authError = 'Error de autenticación.';
  
  // Errores de permisos
  static const String locationPermissionDenied = 'Permisos de ubicación denegados.';
  static const String notificationPermissionDenied = 'Permisos de notificaciones denegados.';
  
  // Errores genéricos
  static const String unknownError = 'Ocurrió un error inesperado.';
  static const String notFound = 'Recurso no encontrado.';
  
  // Errores de validación
  static const String invalidEmail = 'Email inválido.';
  static const String invalidPassword = 'Contraseña inválida.';
  static const String emptyField = 'Este campo es obligatorio.';
}

