class Course {
  final String name;
  final String type; // 'Seminario', 'Clase', 'Tecnológico'
  final String startTime;
  final String endTime;
  final String duration;
  final String teacher;
  final String locationCode;
  final String locationDetail;

  Course({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.teacher,
    required this.locationCode,
    required this.locationDetail,
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

