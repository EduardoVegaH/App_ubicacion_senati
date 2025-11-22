/// Enum para el estado del curso
enum CourseStatus {
  upcoming, // Próximo (más de 10 min antes)
  soon, // Próximo curso (10 min antes)
  inProgress, // En curso
  late, // Llegada tardía (pasó la hora de inicio)
  finished, // Finalizado
}

/// Información del estado de un curso (sin dependencias de Flutter)
class CourseStatusInfo {
  final CourseStatus status;
  final String label;

  CourseStatusInfo({
    required this.status,
    required this.label,
  });
}

