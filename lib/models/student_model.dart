// Enum para el estado de asistencia
enum AttendanceStatus {
  present,      // Presente
  late,         // Tardanza
  absent,       // Ausente
  completed,    // Completado
}

// Modelo para un registro de asistencia individual
class AttendanceRecord {
  final DateTime date;
  final String startTime;
  final String endTime;
  final AttendanceStatus status;
  final bool validatedByGPS;
  final String? notes;

  AttendanceRecord({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.validatedByGPS = false,
    this.notes,
  });
}

// Modelo para el historial completo de un curso
class CourseHistory {
  final String courseName;
  final List<AttendanceRecord> records;
  
  CourseHistory({
    required this.courseName,
    required this.records,
  });

  // Calcular estadísticas
  int get totalSessions => records.length;
  int get totalPresent => records.where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.completed).length;
  int get totalLate => records.where((r) => r.status == AttendanceStatus.late).length;
  int get totalAbsent => records.where((r) => r.status == AttendanceStatus.absent).length;
  int get totalCompleted => records.where((r) => r.status == AttendanceStatus.completed).length;
  
  // Obtener último registro
  AttendanceRecord? get lastRecord {
    if (records.isEmpty) return null;
    final sorted = List<AttendanceRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }
}

class Course {
  final String name;
  final String type; // 'Seminario', 'Clase', 'Tecnológico'
  final String startTime;
  final String endTime;
  final String duration;
  final String teacher;
  final String locationCode;
  final String locationDetail;
  final CourseHistory? history; // Historial de asistencia
  final double? classroomLatitude; // Latitud del salón
  final double? classroomLongitude; // Longitud del salón
  final double? classroomRadius; // Radio en metros para considerar dentro del salón (default: 10m)

  Course({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.teacher,
    required this.locationCode,
    required this.locationDetail,
    this.history,
    this.classroomLatitude,
    this.classroomLongitude,
    this.classroomRadius = 10.0, // Radio por defecto de 10 metros
  });
}

class Student {
  final String name;
  final String id;
  final String semester;
  final String photoUrl;
  final String zonalAddress;
  final String school;
  final String career;
  final String institutionalEmail;
  final List<Course> coursesToday;

  Student({
    required this.name,
    required this.id,
    required this.semester,
    required this.photoUrl,
    required this.zonalAddress,
    required this.school,
    required this.career,
    required this.institutionalEmail,
    required this.coursesToday,
  });
}

