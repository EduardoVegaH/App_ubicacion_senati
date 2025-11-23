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
  }) async {
    if (student.coursesToday.isEmpty) {
      return currentAttendanceStatus;
    }

    try {
      final location = await _locationDataSource.getCurrentLocation();
      final updatedStatus = Map<String, AttendanceStatus>.from(currentAttendanceStatus);

      for (var course in student.coursesToday) {
        final statusInfo = _getCourseStatusUseCase.call(course);
        final isActive = statusInfo.status == CourseStatus.inProgress ||
            statusInfo.status == CourseStatus.late ||
            (statusInfo.status == CourseStatus.finished &&
                courseFirstEntryTime[course.name] != null);

        if (isActive || statusInfo.status == CourseStatus.soon) {
          final attendanceStatus = _validateAttendanceUseCase.call(
            course: course,
            currentLocation: location,
            courseFirstEntryTime: courseFirstEntryTime,
            courseAttendanceStatus: currentAttendanceStatus,
          );
          updatedStatus[course.name] = attendanceStatus;
        }
      }

      return updatedStatus;
    } catch (e) {
      print('Error verificando asistencia de cursos: $e');
      return currentAttendanceStatus;
    }
  }
}

