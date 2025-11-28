import '../../data/data_sources/location_data_source.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/course_status_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import 'get_course_status_use_case.dart';
import 'validate_attendance_use_case.dart';

/// Use case para verificar la asistencia de todos los cursos activos
/// 
/// Itera sobre los cursos del estudiante y valida la asistencia de cada uno
/// basándose en la ubicación actual y el estado del curso.
class CheckCoursesAttendanceUseCase {
  final LocationDataSource _locationDataSource;
  final GetCourseStatusUseCase _getCourseStatusUseCase;
  final ValidateAttendanceUseCase _validateAttendanceUseCase;

  CheckCoursesAttendanceUseCase(
    this._locationDataSource,
    this._getCourseStatusUseCase,
    this._validateAttendanceUseCase,
  );

  /// Verificar asistencia de todos los cursos activos
  /// 
  /// Retorna un mapa con el estado de asistencia de cada curso
  Future<Map<String, AttendanceStatus>> call({
    required StudentEntity student,
    required Map<String, DateTime?> courseFirstEntryTime,
    required Map<String, AttendanceStatus> currentAttendanceStatus,
    String? campusStatus, // Estado del campus (dentro/fuera)
  }) async {
    if (student.coursesToday.isEmpty) {
      return currentAttendanceStatus;
    }

    try {
      final location = await _locationDataSource.getCurrentLocation();
      final updatedStatus = Map<String, AttendanceStatus>.from(currentAttendanceStatus);

      for (var course in student.coursesToday) {
        // Validar asistencia para todos los cursos
        final attendanceStatus = _validateAttendanceUseCase.call(
          course: course,
          currentLocation: location,
          courseFirstEntryTime: courseFirstEntryTime,
          courseAttendanceStatus: currentAttendanceStatus,
          campusStatus: campusStatus ?? 'dentro', // Usar el campusStatus pasado o 'dentro' por defecto
        );
        
        // Si retorna null, significa que el curso aún no ha comenzado (solo para Redes antes de las 7:15)
        // En ese caso, no actualizamos el estado para que se muestre el mensaje especial
        if (attendanceStatus != null) {
          updatedStatus[course.name] = attendanceStatus;
        }
        // Si es null, no establecemos nada en updatedStatus, y el CourseCard mostrará el mensaje especial
      }

      return updatedStatus;
    } catch (e) {
      // No imprimir errores de timeout - el servicio ya maneja el fallback silenciosamente
      // Solo imprimir errores críticos que no sean timeouts
      if (!e.toString().contains('TimeoutException')) {
        print('Error verificando asistencia de cursos: $e');
      }
      return currentAttendanceStatus;
    }
  }
}

