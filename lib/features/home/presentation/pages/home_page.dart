import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../../../app/styles/app_styles.dart';
import '../../../../core/widgets/floating_chatbot/floating_chatbot.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../data/index.dart';
import '../../domain/index.dart';
import '../widgets/student_info_header.dart';
import '../widgets/course_card.dart';
import '../widgets/home_drawer.dart';
import '../widgets/academic_status_block.dart';

/// Página principal de home (completamente refactorizada con Clean Architecture)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Repositorios y data sources
  late final HomeRepository _repository;
  late final LocationDataSource _locationDataSource;
  late final NotificationDataSource _notificationDataSource;

  // Use cases
  late final GetStudentDataUseCase _getStudentDataUseCase;
  late final UpdateLocationUseCase _updateLocationUseCase;
  late final CheckCampusStatusUseCase _checkCampusStatusUseCase;
  late final GetCourseStatusUseCase _getCourseStatusUseCase;
  late final ValidateAttendanceUseCase _validateAttendanceUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final GenerateCourseHistoryUseCase _generateCourseHistoryUseCase;

  // Estado
  StudentEntity? _student;
  bool _loading = true;
  String _campusStatus = "Desconocido";
  final Map<String, AttendanceStatus> _courseAttendanceStatus = {};
  final Map<String, DateTime?> _courseFirstEntryTime = {};

  // Timers
  Timer? _gpsTimer;
  Timer? _courseStatusTimer;
  Timer? _attendanceCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _loadStudentData();
    _initializeNotifications();
    _startTimers();
  }

  void _initializeDependencies() {
    // Inicializar data sources
    _locationDataSource = LocationDataSource();
    _notificationDataSource = NotificationDataSource();
    final homeRemoteDataSource = HomeRemoteDataSource();

    // Inicializar repositorio
    _repository = HomeRepositoryImpl(
      homeRemoteDataSource,
      _locationDataSource,
    );

    // Inicializar use cases
    _getStudentDataUseCase = GetStudentDataUseCase(_repository);
    _updateLocationUseCase = UpdateLocationUseCase(_repository);
    _checkCampusStatusUseCase = CheckCampusStatusUseCase();
    _getCourseStatusUseCase = GetCourseStatusUseCase();
    _validateAttendanceUseCase = ValidateAttendanceUseCase(_getCourseStatusUseCase);
    _logoutUseCase = LogoutUseCase(_repository);
    _generateCourseHistoryUseCase = GenerateCourseHistoryUseCase();
  }

  Future<void> _loadStudentData() async {
    try {
      final student = await _getStudentDataUseCase.call();
      if (student != null) {
        // Si no hay cursos desde Firebase, usar cursos de ejemplo (como en el código antiguo)
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

        setState(() {
          _student = StudentEntity(
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
          _loading = false;
        });

        // Programar notificaciones
        await _scheduleNotifications(coursesWithHistory);
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos del estudiante: $e');
      setState(() {
        _loading = false;
      });
    }
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
        locationCode: 'IND - TORRE C 60TC - 604',
        locationDetail: 'Torre C, Piso 6, Salón 604',
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
        locationCode: 'IND - TORRE A 60TA - 604',
        locationDetail: 'Torre A, Piso 6, Salón 604',
        classroomLatitude: -11.997100,
        classroomLongitude: -77.061400,
        classroomRadius: 10.0,
      ),
    ];
  }

  Future<void> _scheduleNotifications(List<CourseEntity> courses) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final hasPermissions = await _notificationDataSource.checkPermissions();
      if (!hasPermissions) {
        print('⚠️ ADVERTENCIA: Las notificaciones no están habilitadas');
      }

      // Programar notificación de prueba
      await _notificationDataSource.scheduleTestNotification(10);

      if (courses.isNotEmpty) {
        await _notificationDataSource.scheduleAllCourseNotifications(courses);
      }
    } catch (e) {
      print('Error programando notificaciones: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationDataSource.initialize();
  }

  void _startTimers() {
    // Timer para actualizar ubicación cada 5 segundos
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateLocation();
    });

    // Timer para actualizar estado de cursos cada minuto
    _courseStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    // Timer para validar asistencia cada 30 segundos
    _attendanceCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkCourseAttendance();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final location = await _locationDataSource.getCurrentLocation();
      final isInside = _checkCampusStatusUseCase.call(location);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final status = isInside ? "Dentro del campus" : "Fuera del campus";
      
      setState(() {
        _campusStatus = status;
      });

      await _updateLocationUseCase.call(
        userId: user.uid,
        location: location,
        campusStatus: status,
      );
    } catch (e) {
      print("Error actualizando ubicación: $e");
    }
  }

  Future<void> _checkCourseAttendance() async {
    if (_student == null) return;

    try {
      final location = await _locationDataSource.getCurrentLocation();

      for (var course in _student!.coursesToday) {
        final statusInfo = _getCourseStatusUseCase.call(course);
        final isActive = statusInfo.status == CourseStatus.inProgress ||
            statusInfo.status == CourseStatus.late ||
            (statusInfo.status == CourseStatus.finished &&
                _courseFirstEntryTime[course.name] != null);

        if (isActive || statusInfo.status == CourseStatus.soon) {
          final attendanceStatus = _validateAttendanceUseCase.call(
            course: course,
            currentLocation: location,
            courseFirstEntryTime: _courseFirstEntryTime,
            courseAttendanceStatus: _courseAttendanceStatus,
          );
          _courseAttendanceStatus[course.name] = attendanceStatus;

          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      print('Error verificando asistencia: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _logoutUseCase.call();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  List<CourseEntity> _sortCoursesByTime(List<CourseEntity> courses) {
    final sorted = List<CourseEntity>.from(courses);
    sorted.sort((a, b) {
      final timeA = _parseTime(a.startTime);
      final timeB = _parseTime(b.startTime);

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;

      return timeA.compareTo(timeB);
    });
    return sorted;
  }

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


  String _getCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} De ${months[now.month - 1]} De ${now.year}';
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _courseStatusTimer?.cancel();
    _attendanceCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppStyles.surfaceColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return Scaffold(
        backgroundColor: AppStyles.surfaceColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sortedCourses = _sortCoursesByTime(_student!.coursesToday);

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      drawer: HomeDrawer(
        student: _student,
        onLogout: _handleLogout,
        isLargePhone: isLargePhone,
        isTablet: isTablet,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header con información del estudiante
                Builder(
                  builder: (context) => StudentInfoHeader(
                    student: _student!,
                    campusStatus: _campusStatus,
                    isLargePhone: isLargePhone,
                    isTablet: isTablet,
                    onMenuTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                // Contenido scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isLargePhone ? 20 : (isTablet ? 24 : 16),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sección de Información Académica
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: isLargePhone ? 24 : (isTablet ? 28 : 20),
                            ),
                            child: AcademicStatusBlock(student: _student!),
                          ),
                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          SizedBox(
                            height: isLargePhone ? 24 : (isTablet ? 28 : 20),
                          ),
                          // Sección de Cursos Programados
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título con icono y fecha
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: AppStyles.primaryColor,
                                    size: isLargePhone
                                        ? 26
                                        : (isTablet ? 28 : 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cursos Programados Hoy',
                                    style: TextStyle(
                                      fontSize: isLargePhone
                                          ? 20
                                          : (isTablet ? 22 : 18),
                                      fontWeight: FontWeight.bold,
                                      color: AppStyles.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: isLargePhone ? 10 : (isTablet ? 12 : 8),
                              ),
                              Text(
                                _getCurrentDate(),
                                style: TextStyle(
                                  fontSize: isLargePhone
                                      ? 15
                                      : (isTablet ? 16 : 14),
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                              SizedBox(
                                height: isLargePhone
                                    ? 22
                                    : (isTablet ? 24 : 20),
                              ),
                              // Lista de cursos ordenados por horario
                              if (sortedCourses.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(isLargePhone ? 24 : (isTablet ? 28 : 20)),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.school_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay cursos programados para hoy',
                                          style: TextStyle(
                                            fontSize: isLargePhone ? 16 : (isTablet ? 18 : 14),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...sortedCourses.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final course = entry.value;
                                  final attendanceStatus = _courseAttendanceStatus[course.name];
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLargePhone
                                          ? 18
                                          : (isTablet ? 20 : 16),
                                    ),
                                    child: CourseCard(
                                      course: course,
                                      index: index,
                                      attendanceStatus: attendanceStatus,
                                      getCourseStatusUseCase: _getCourseStatusUseCase,
                                    ),
                                  );
                                }),
                              // Información adicional
                              Padding(
                                padding: EdgeInsets.only(
                                  top: isLargePhone ? 18 : (isTablet ? 20 : 16),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isLargePhone ? 18 : (isTablet ? 20 : 16),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppStyles.lightGrayBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: AppStyles.primaryColor,
                                            size: isLargePhone
                                                ? 21
                                                : (isTablet ? 22 : 20),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Presiona el botón "Ver Ubicación en Mapa" en cada curso para navegar al salón',
                                              style: TextStyle(
                                                fontSize: isLargePhone
                                                    ? 14
                                                    : (isTablet ? 15 : 13),
                                                color: AppStyles.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: isLargePhone
                                            ? 10
                                            : (isTablet ? 12 : 8),
                                      ),
                                      Text(
                                        'Total de cursos hoy: ${sortedCourses.length}',
                                        style: TextStyle(
                                          fontSize: isLargePhone
                                              ? 14
                                              : (isTablet ? 15 : 13),
                                          fontWeight: FontWeight.bold,
                                          color: AppStyles.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chatbot flotante
          FloatingChatbot(
            studentData: _student != null
                ? {
                    'NameEstudent': _student!.name,
                    'IdEstudiante': _student!.id,
                    'Semestre': _student!.semester,
                    'Campus': _student!.zonalAddress,
                    'Escuela': _student!.school,
                    'Carrera': _student!.career,
                    'CorreoInstud': _student!.institutionalEmail,
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
