import 'package:geolocator/geolocator.dart';
import '../entities/attendance_entity.dart';
import '../entities/student_entity.dart';
import '../entities/location_entity.dart';
import 'get_course_status_use_case.dart';

/// Use case para validar asistencia basada en GPS
class ValidateAttendanceUseCase {
  final GetCourseStatusUseCase _getCourseStatusUseCase;

  ValidateAttendanceUseCase(this._getCourseStatusUseCase);

  /// Valida el estado de asistencia de un curso
  AttendanceStatus? call({
    required CourseEntity course,
    required LocationEntity currentLocation,
    required Map<String, DateTime?> courseFirstEntryTime,
    required Map<String, AttendanceStatus> courseAttendanceStatus,
    String? campusStatus, // Estado del campus (dentro/fuera)
  }) {
    final now = DateTime.now();
    final startTime = _parseTime(course.startTime);
    final endTime = _parseTime(course.endTime);

    // Caso especial: REDES DE COMPUTADORAS tiene plazo hasta las 7:15 PM
    if (course.name.toUpperCase().contains('REDES DE COMPUTADORAS')) {
      final deadlineTime = _parseTime('7:15 PM');
      if (deadlineTime != null) {
        if (now.isBefore(deadlineTime)) {
          // Antes de las 7:15 PM: retornar null para mostrar "El curso comienza a las 7:15"
          return null;
        } else {
          // Después de las 7:15 PM, validar por campusStatus
          if (campusStatus?.toLowerCase().contains('dentro') == true ||
              campusStatus?.toLowerCase().contains('presente') == true) {
            // Si está dentro del campus, es presente (llegó temprano)
            if (courseFirstEntryTime[course.name] == null) {
              courseFirstEntryTime[course.name] = now;
            }
            return AttendanceStatus.present;
          } else {
            // Si no está en el campus, es tardanza (llegó tarde)
            if (courseFirstEntryTime[course.name] == null) {
              courseFirstEntryTime[course.name] = now;
            }
            return AttendanceStatus.late;
          }
        }
      }
    }

    // Para todos los demás cursos: aparecer como presente
    if (courseFirstEntryTime[course.name] == null) {
      courseFirstEntryTime[course.name] = now;
    }
    return AttendanceStatus.present;
  }

  /// Valida asistencia con lógica normal (para Redes antes de las 7:15 PM)
  AttendanceStatus _validateNormalAttendance(
    CourseEntity course,
    LocationEntity currentLocation,
    Map<String, DateTime?> courseFirstEntryTime,
    Map<String, AttendanceStatus> courseAttendanceStatus,
    DateTime? startTime,
    DateTime? endTime,
    DateTime now,
  ) {
    if (startTime == null || endTime == null) {
      return AttendanceStatus.absent;
    }

    final isWithinSchedule = now.isAfter(startTime) && now.isBefore(endTime);
    final isAfterEnd = now.isAfter(endTime);

    // Si ya pasó el horario y nunca ingresó, es ausente
    if (isAfterEnd && courseFirstEntryTime[course.name] == null) {
      return AttendanceStatus.absent;
    }

    // Si está dentro del horario o ya pasó pero ingresó
    if (isWithinSchedule || (isAfterEnd && courseFirstEntryTime[course.name] != null)) {
      final isInside = _isInsideClassroom(currentLocation, course);

      if (isInside) {
        // Si es la primera vez que ingresa, registrar la hora
        if (courseFirstEntryTime[course.name] == null) {
          courseFirstEntryTime[course.name] = now;

          // Verificar si ingresó a tiempo o tarde
          if (now.isAfter(startTime.add(const Duration(minutes: 5)))) {
            return AttendanceStatus.late;
          } else {
            return AttendanceStatus.present;
          }
        } else {
          // Ya ingresó antes, mantener el estado que tenía
          return courseAttendanceStatus[course.name] ?? AttendanceStatus.present;
        }
      } else {
        // Si salió del salón, mantener el último estado registrado
        return courseAttendanceStatus[course.name] ?? AttendanceStatus.absent;
      }
    }

    // Si aún no ha empezado el curso, mantener ausente por defecto
    return AttendanceStatus.absent;
  }

  /// Verifica si el usuario está dentro del salón
  bool _isInsideClassroom(LocationEntity currentLocation, CourseEntity course) {
    if (course.classroomLatitude == null || course.classroomLongitude == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      course.classroomLatitude!,
      course.classroomLongitude!,
    );

    return distance <= (course.classroomRadius ?? 10.0);
  }

  /// Parsea tiempo de formato "7:00 AM" a DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final amPm = parts[1].toUpperCase();

      final timeParts = timePart.split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return null;
    }
  }
}

