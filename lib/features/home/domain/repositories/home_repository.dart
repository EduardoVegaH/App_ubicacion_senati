import '../entities/student_entity.dart';
import '../entities/location_entity.dart';

/// Repositorio para la feature home
abstract class HomeRepository {
  /// Obtener datos del estudiante actual
  Future<StudentEntity?> getStudentData();
  
  /// Actualizar ubicación del usuario en Firestore
  Future<void> updateUserLocation({
    required String userId,
    required LocationEntity location,
    required String campusStatus,
  });
  
  /// Cerrar sesión
  Future<void> logout();
}

