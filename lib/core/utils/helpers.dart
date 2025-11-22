/// Utilidades y funciones helper compartidas
class AppHelpers {
  /// Formatea una fecha a string legible
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Formatea una fecha con hora
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Valida formato de email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Valida formato de ID de estudiante
  static bool isValidStudentId(String studentId) {
    return RegExp(r'^[A-Z0-9]+$').hasMatch(studentId);
  }
}

