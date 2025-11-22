import '../entities/attendance_entity.dart';
import '../entities/student_entity.dart';

/// Use case para generar historial de ejemplo de un curso
class GenerateCourseHistoryUseCase {
  /// Genera historial de ejemplo para un curso
  CourseHistoryEntity call({
    required String courseName,
    required String startTime,
    required String endTime,
  }) {
    final now = DateTime.now();
    final records = <AttendanceRecordEntity>[];

    // Generar registros de las últimas 2 semanas
    for (int i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Solo incluir días de semana (lunes a viernes)
      if (date.weekday >= 1 && date.weekday <= 5) {
        AttendanceStatus status;
        bool validatedByGPS = false;

        // Simular diferentes estados
        if (i % 7 == 0) {
          status = AttendanceStatus.absent;
        } else if (i % 5 == 0) {
          status = AttendanceStatus.late;
          validatedByGPS = true;
        } else if (i == 0) {
          // Hoy - verificar si ya pasó
          final endTimeParsed = _parseTime(endTime);
          if (endTimeParsed != null && now.isAfter(endTimeParsed)) {
            status = AttendanceStatus.completed;
            validatedByGPS = true;
          } else {
            status = AttendanceStatus.present;
            validatedByGPS = true;
          }
        } else {
          status = AttendanceStatus.present;
          validatedByGPS = i % 3 != 0; // Algunos validados por GPS
        }

        records.add(
          AttendanceRecordEntity(
            date: date,
            startTime: startTime,
            endTime: endTime,
            status: status,
            validatedByGPS: validatedByGPS,
          ),
        );
      }
    }

    return CourseHistoryEntity(courseName: courseName, records: records);
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

