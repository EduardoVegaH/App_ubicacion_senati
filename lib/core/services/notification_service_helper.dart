/// Helper temporal para NotificationService y compatibilidad con modelos antiguos
/// Contiene las clases antiguas (Student, Course, CourseHistory, AttendanceRecord)
/// TODO: Actualizar NotificationService y otros servicios para usar entidades de Clean Architecture

class Course {
  final String name;
  final String type;
  final String startTime;
  final String endTime;
  final String duration;
  final String teacher;
  final String locationCode;
  final String locationDetail;
  final CourseHistory? history;
  final double? classroomLatitude;
  final double? classroomLongitude;
  final double? classroomRadius;

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
    this.classroomRadius = 10.0,
  });
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class AttendanceRecord {
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.notes,
  });
}

class CourseHistory {
  final List<AttendanceRecord> records;

  CourseHistory({required this.records});
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
