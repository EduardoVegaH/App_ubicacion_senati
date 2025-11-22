/// Enum para el estado de asistencia
enum AttendanceStatus {
  present,      // Presente
  late,         // Tardanza
  absent,       // Ausente
  completed,    // Completado
}

/// Información de un registro de asistencia
class AttendanceRecordEntity {
  final DateTime date;
  final String startTime;
  final String endTime;
  final AttendanceStatus status;
  final bool validatedByGPS;
  final String? notes;

  AttendanceRecordEntity({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.validatedByGPS = false,
    this.notes,
  });
}

/// Historial completo de un curso
class CourseHistoryEntity {
  final String courseName;
  final List<AttendanceRecordEntity> records;
  
  CourseHistoryEntity({
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
  AttendanceRecordEntity? get lastRecord {
    if (records.isEmpty) return null;
    final sorted = List<AttendanceRecordEntity>.from(records)..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }
}

/// Información de badge de asistencia (sin dependencias de Flutter)
class AttendanceBadgeInfo {
  final String label;
  final String colorName; // 'green', 'red', 'orange', etc.

  AttendanceBadgeInfo({
    required this.label,
    required this.colorName,
  });
}

