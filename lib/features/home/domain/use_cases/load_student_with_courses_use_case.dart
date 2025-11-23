import '../entities/student_entity.dart';
import 'get_student_data_use_case.dart';
import 'generate_course_history_use_case.dart';

/// Use case compuesto para cargar datos del estudiante con cursos procesados
/// Encapsula la lógica de:
/// - Obtener datos del estudiante
/// - Usar cursos de ejemplo si no hay cursos en Firebase
/// - Generar historial para cursos que no lo tienen
class LoadStudentWithCoursesUseCase {
  final GetStudentDataUseCase _getStudentDataUseCase;
  final GenerateCourseHistoryUseCase _generateCourseHistoryUseCase;

  LoadStudentWithCoursesUseCase({
    required GetStudentDataUseCase getStudentDataUseCase,
    required GenerateCourseHistoryUseCase generateCourseHistoryUseCase,
  })  : _getStudentDataUseCase = getStudentDataUseCase,
        _generateCourseHistoryUseCase = generateCourseHistoryUseCase;

  Future<StudentEntity?> call() async {
    final student = await _getStudentDataUseCase.call();
    if (student == null) return null;

    // Si no hay cursos desde Firebase, usar cursos de ejemplo
    List<CourseEntity> coursesToUse = student.coursesToday;
    
    if (coursesToUse.isEmpty) {
      print('⚠️ No hay cursos en Firebase, usando cursos de ejemplo');
      coursesToUse = _getExampleCourses();
    }
    
    // Generar historial para cada curso si no existe
    final coursesWithHistory = coursesToUse.map((course) {
      if (course.history == null) {
        final history = _generateCourseHistoryUseCase.call(
          courseName: course.name,
          startTime: course.startTime,
          endTime: course.endTime,
        );
        return CourseEntity(
          name: course.name,
          type: course.type,
          startTime: course.startTime,
          endTime: course.endTime,
          duration: course.duration,
          teacher: course.teacher,
          locationCode: course.locationCode,
          locationDetail: course.locationDetail,
          classroomLatitude: course.classroomLatitude,
          classroomLongitude: course.classroomLongitude,
          classroomRadius: course.classroomRadius,
          history: history,
        );
      }
      return course;
    }).toList();

    return StudentEntity(
      name: student.name,
      id: student.id,
      semester: student.semester,
      photoUrl: student.photoUrl,
      zonalAddress: student.zonalAddress,
      school: student.school,
      career: student.career,
      institutionalEmail: student.institutionalEmail,
      coursesToday: coursesWithHistory,
    );
  }

  /// Cursos de ejemplo (del código antiguo) para usar cuando no hay cursos en Firebase
  List<CourseEntity> _getExampleCourses() {
    return [
      CourseEntity(
        name: 'SEMINARIO COMPLEMENT PRÁCTI',
        type: 'Seminario',
        startTime: '7:00 AM',
        endTime: '10:00 AM',
        duration: '7:00 AM - 10:00 AM',
        teacher: 'MANSILLA NEYRA, JUAN RAMON',
        locationCode: 'IND - TORRE B 60TB - 200',
        locationDetail: 'Torre B, Piso 2, Salón 200',
        classroomLatitude: -11.997200,
        classroomLongitude: -77.061500,
        classroomRadius: 10.0,
      ),
      CourseEntity(
        name: 'DESARROLLO HUMANO',
        type: 'Clase',
        startTime: '3:40 PM',
        endTime: '5:00 PM',
        duration: '3:40 PM - 5:00 PM',
        teacher: 'GONZALES LEON, JACQUELINE CORAL',
        locationCode: 'IND - COMEDOR PISO 1',
        locationDetail: 'Comedor, Piso 1',
        classroomLatitude: -11.997300,
        classroomLongitude: -77.061600,
        classroomRadius: 10.0,
      ),
      CourseEntity(
        name: 'REDES DE COMPUTADORAS',
        type: 'Tecnológico',
        startTime: '7:00 AM',
        endTime: '9:15 AM',
        duration: '7:00 AM - 9:15 AM',
        teacher: 'MANSILLA NEYRA, JUAN RAMON',
        locationCode: 'IND - TORRE A 60TA - 202',
        locationDetail: 'Torre A, Piso 2, Salón 202',
        classroomLatitude: -11.997100,
        classroomLongitude: -77.061400,
        classroomRadius: 10.0,
      ),
    ];
  }
}

