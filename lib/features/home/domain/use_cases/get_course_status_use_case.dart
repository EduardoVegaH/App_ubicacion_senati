import '../entities/course_status_entity.dart';
import '../entities/student_entity.dart';

/// Use case para obtener el estado de un curso
class GetCourseStatusUseCase {
  CourseStatusInfo call(CourseEntity course) {
    final now = DateTime.now();
    final startTime = _parseTime(course.startTime);
    final endTime = _parseTime(course.endTime);

    if (startTime == null || endTime == null) {
      return CourseStatusInfo(
        status: CourseStatus.upcoming,
        label: 'Horario no disponible',
      );
    }

    // Calcular diferencia en minutos
    final minutesUntilStart = startTime.difference(now).inMinutes;
    final minutesUntilEnd = endTime.difference(now).inMinutes;

    // Finalizado
    if (minutesUntilEnd <= 0) {
      return CourseStatusInfo(
        status: CourseStatus.finished,
        label: 'Finalizado',
      );
    }

    // Llegada tardía (pasó la hora de inicio pero aún no termina)
    if (minutesUntilStart < -5 && minutesUntilEnd > 0) {
      return CourseStatusInfo(
        status: CourseStatus.late,
        label: 'Llegada tardía',
      );
    }

    // En curso
    if (minutesUntilStart <= 0 && minutesUntilEnd > 0) {
      return CourseStatusInfo(
        status: CourseStatus.inProgress,
        label: 'En curso',
      );
    }

    // Próximo curso (10 minutos antes)
    if (minutesUntilStart > 0 && minutesUntilStart <= 10) {
      return CourseStatusInfo(
        status: CourseStatus.soon,
        label: 'Próximo curso',
      );
    }

    // Próximo (más de 10 minutos)
    return CourseStatusInfo(
      status: CourseStatus.upcoming,
      label: 'Próximo',
    );
  }

  /// Parsea tiempo de formato "7:00 AM" a DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) {
        return null;
      }

      final timePart = parts[0];
      final amPm = parts[1].toUpperCase();

      final timeParts = timePart.split(':');
      if (timeParts.length != 2) {
        return null;
      }

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

