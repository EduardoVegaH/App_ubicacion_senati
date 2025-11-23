import '../../domain/entities/student_entity.dart';
import '../../../../core/services/notification_service_helper.dart' as old;

/// Modelo de datos de estudiante (con serialización)
class StudentModel extends StudentEntity {
  StudentModel({
    required super.name,
    required super.id,
    required super.semester,
    required super.photoUrl,
    required super.zonalAddress,
    required super.school,
    required super.career,
    required super.institutionalEmail,
    required super.coursesToday,
  });

  /// Crear desde Firestore
  factory StudentModel.fromFirestore(Map<String, dynamic> data) {
    final courses = (data['cursos'] as List<dynamic>? ?? []).map((c) {
      return CourseModel(
        name: c['nombre'] ?? '',
        type: c['tipo'] ?? '',
        startTime: c['horaInicio'] ?? '',
        endTime: c['horaFin'] ?? '',
        duration: c['duracion'] ?? '',
        teacher: c['profesor'] ?? '',
        locationCode: c['codigoSalon'] ?? '',
        locationDetail: c['detalleSalon'] ?? '',
        classroomLatitude: c['latitudSalon']?.toDouble(),
        classroomLongitude: c['longitudSalon']?.toDouble(),
        classroomRadius: c['radioSalon']?.toDouble() ?? 10.0,
      );
    }).toList();

    // Intentar múltiples nombres de campo para la foto (compatibilidad)
    final photoUrl = data['foto'] ?? 
                     data['Foto'] ?? 
                     data['photoUrl'] ?? 
                     data['photo'] ?? 
                     data['fotoUrl'] ?? 
                     '';

    return StudentModel(
      name: data['NameEstudent'] ?? '',
      id: data['IdEstudiante'] ?? '',
      semester: data['Semestre'] ?? '',
      photoUrl: photoUrl,
      // Intentar ambos nombres de campo para compatibilidad
      zonalAddress: data['Campus'] ?? data['DireccionZonal'] ?? '',
      school: data['Escuela'] ?? '',
      career: data['Carrera'] ?? '',
      institutionalEmail: data['CorreoInstud'] ?? '',
      coursesToday: courses,
    );
  }

  /// Convertir a entidad
  StudentEntity toEntity() {
    return StudentEntity(
      name: name,
      id: id,
      semester: semester,
      photoUrl: photoUrl,
      zonalAddress: zonalAddress,
      school: school,
      career: career,
      institutionalEmail: institutionalEmail,
      coursesToday: coursesToday,
    );
  }

  /// Convertir desde modelo antiguo (temporal para compatibilidad)
  factory StudentModel.fromOldModel(old.Student oldStudent) {
    return StudentModel(
      name: oldStudent.name,
      id: oldStudent.id,
      semester: oldStudent.semester,
      photoUrl: oldStudent.photoUrl,
      zonalAddress: oldStudent.zonalAddress,
      school: oldStudent.school,
      career: oldStudent.career,
      institutionalEmail: oldStudent.institutionalEmail,
      coursesToday: oldStudent.coursesToday.map((c) {
        return CourseModel(
          name: c.name,
          type: c.type,
          startTime: c.startTime,
          endTime: c.endTime,
          duration: c.duration,
          teacher: c.teacher,
          locationCode: c.locationCode,
          locationDetail: c.locationDetail,
          classroomLatitude: c.classroomLatitude,
          classroomLongitude: c.classroomLongitude,
          classroomRadius: c.classroomRadius,
        );
      }).toList(),
    );
  }
}

/// Modelo de curso
class CourseModel extends CourseEntity {
  CourseModel({
    required super.name,
    required super.type,
    required super.startTime,
    required super.endTime,
    required super.duration,
    required super.teacher,
    required super.locationCode,
    required super.locationDetail,
    super.classroomLatitude,
    super.classroomLongitude,
    super.classroomRadius,
    super.history,
  });

  /// Convertir a entidad
  CourseEntity toEntity() {
    return CourseEntity(
      name: name,
      type: type,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      teacher: teacher,
      locationCode: locationCode,
      locationDetail: locationDetail,
      classroomLatitude: classroomLatitude,
      classroomLongitude: classroomLongitude,
      classroomRadius: classroomRadius,
      history: history,
    );
  }
}

