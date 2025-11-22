import 'attendance_entity.dart';

/// Entidad de estudiante (sin dependencias externas)
class StudentEntity {
  final String name;
  final String id;
  final String semester;
  final String photoUrl;
  final String zonalAddress;
  final String school;
  final String career;
  final String institutionalEmail;
  final List<CourseEntity> coursesToday;

  StudentEntity({
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

/// Entidad de curso
class CourseEntity {
  final String name;
  final String type;
  final String startTime;
  final String endTime;
  final String duration;
  final String teacher;
  final String locationCode;
  final String locationDetail;
  final double? classroomLatitude;
  final double? classroomLongitude;
  final double? classroomRadius;
  final CourseHistoryEntity? history;

  CourseEntity({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.teacher,
    required this.locationCode,
    required this.locationDetail,
    this.classroomLatitude,
    this.classroomLongitude,
    this.classroomRadius = 10.0,
    this.history,
  });
}

