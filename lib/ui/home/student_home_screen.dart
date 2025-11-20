import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../login/login_screen.dart';
import '../../services/firebase_service.dart';
import 'dart:async'; // Tiempo de espera
import 'package:cloud_firestore/cloud_firestore.dart'; // firestore
import 'package:firebase_auth/firebase_auth.dart'; // firebase auth
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'courses_list_screen.dart';
import '../bathrooms/bathroom_status_screen.dart';
import 'friends_screen.dart';
import '../widgets/tower_map_viewer.dart';
import '../navigation/navigation_map_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../widgets/floating_chatbot.dart';
import '../admin/salones_admin_screen.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

// Enum para el estado del curso
enum CourseStatus {
  upcoming,      // Próximo (más de 10 min antes)
  soon,          // Próximo curso (10 min antes)
  inProgress,    // En curso
  late,          // Llegada tardía (pasó la hora de inicio)
  finished,      // Finalizado
}

// Clase helper para el estado del curso
class CourseStatusInfo {
  final CourseStatus status;
  final String label;
  final Color color;
  final IconData icon;

  CourseStatusInfo({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
  });
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService();
  Student? student;
  bool loading = true;
  late String userUid; // UID actual de FirebaseAuth
  String campusStatus = "Desconocido"; // Texto: Dentro/Fuera del campus
  Timer? gpsTimer; // Para el Timer periódico
  Timer? courseStatusTimer; // Timer para actualizar estado de cursos
  Timer? attendanceCheckTimer; // Timer para validar asistencia GPS
  
  // Mapa para rastrear el estado de asistencia GPS de cada curso
  final Map<String, AttendanceStatus> _courseAttendanceStatus = {};
  final Map<String, DateTime?> _courseFirstEntryTime = {}; // Primera vez que ingresó al salón
  final Map<String, bool> _courseMonitoringActive = {}; // Si está monitoreando este curso

  //Polígono aproximado del campus SENATI INDEPENDENCIA
  final List<LatLng> campusPolygon = const [
    LatLng(-11.997982, -77.062461),
    LatLng(-11.997751, -77.061253),
    LatLng(-11.997523, -77.060133),
    LatLng(-11.997359, -77.058693),
    LatLng(-11.998306, -77.058565),
    LatLng(-11.998931, -77.058429),
    LatLng(-11.999843, -77.058283),
    LatLng(-12.000013, -77.058421),
    LatLng(-12.000218, -77.058479),
    LatLng(-12.000402, -77.059963),
    LatLng(-12.000665, -77.061691),
    LatLng(-12.000668, -77.062109),
    LatLng(-11.999955, -77.062196),
    LatLng(-11.999600, -77.062255),
    LatLng(-11.998928, -77.062383),
    LatLng(-11.998417, -77.062422),
  ];

  @override
  void initState() {
    super.initState();
    //1) Obtiene el UID del usuario logueado
    userUid = FirebaseAuth.instance.currentUser!.uid;
    // 2) Inicializar notificaciones locales (sin bloquear)
    _initializeNotifications();
    // 3) Carga los datos del estudiante
    _loadStudentData();
    // 4) Activar el GPS automático cada 5 segundos
    gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateLocation();
    });
    // 5) Actualizar estado de cursos cada minuto
    courseStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Forzar actualización para recalcular estados
        });
      }
    });
    // 6) Validar asistencia GPS cada 30 segundos
    attendanceCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkCourseAttendance();
    });
  }

  // Inicializar notificaciones locales (con manejo de errores)
  Future<void> _initializeNotifications() async {
    try {
      print('🔔 Inicializando servicio de notificaciones...');
      await NotificationService.initialize();
      print('✅ Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar notificaciones: $e');
      // No bloquear la app si falla la inicialización de notificaciones
    }
  }
  
  @override
  void dispose() {
    gpsTimer?.cancel();
    courseStatusTimer?.cancel();
    attendanceCheckTimer?.cancel();
    super.dispose();
  }

  // Función helper para generar historial de ejemplo
  CourseHistory _generateSampleHistory(String courseName, String startTime, String endTime) {
    final now = DateTime.now();
    final records = <AttendanceRecord>[];
    
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
        
        records.add(AttendanceRecord(
          date: date,
          startTime: startTime,
          endTime: endTime,
          status: status,
          validatedByGPS: validatedByGPS,
        ));
      }
    }
    
    return CourseHistory(
      courseName: courseName,
      records: records,
    );
  }

  // Datos de ejemplo del estudiante
  Future<void> _loadStudentData() async {
    final data = await _authService.getUserData();
    if (data != null) {
      setState(() {
        student = Student(
          //Simular carga datos
          name: (data['NameEstudent'] ?? '').toString().toUpperCase(),
          id: data['IdEstudiante'] ?? '',
          semester: data['Semestre'] ?? '',
          photoUrl: data['foto'] ?? '', // Se usará un placeholder
          zonalAddress: data['Campus'] ?? '',
          school: data['Escuela'] ?? '',
          career: data['Carrera'] ?? '',
          institutionalEmail: data['CorreoInstud'] ?? '',
          coursesToday: [
            Course(
              name: 'SEMINARIO COMPLEMENT PRÁCTI',
              type: 'Seminario',
              startTime: '7:00 AM',
              endTime: '10:00 AM',
              duration: '7:00 AM - 10:00 AM',
              teacher: 'MANSILLA NEYRA, JUAN RAMON',
              locationCode: 'IND - TORRE B 60TB - 200',
              locationDetail: 'Torre B, Piso 2, Salón 200',
              history: _generateSampleHistory('SEMINARIO COMPLEMENT PRÁCTI', '7:00 AM', '10:00 AM'),
              classroomLatitude: -11.997200, // Coordenadas de ejemplo del salón
              classroomLongitude: -77.061500,
              classroomRadius: 10.0,
            ),
            Course(
              name: 'DESARROLLO HUMANO',
              type: 'Clase',
              startTime: '3:40 PM',
              endTime: '5:00 PM',
              duration: '3:40 PM - 5:00 PM',
              teacher: 'GONZALES LEON, JACQUELINE CORAL',
              locationCode: 'IND - TORRE C 60TC - 604',
              locationDetail: 'Torre C, Piso 6, Salón 604',
              history: _generateSampleHistory('DESARROLLO HUMANO', '3:40 PM', '5:00 PM'),
              classroomLatitude: -11.997300, // Coordenadas de ejemplo del salón
              classroomLongitude: -77.061600,
              classroomRadius: 10.0,
            ),
            Course(
              name: 'REDES DE COMPUTADORAS',
              type: 'Tecnológico',
              startTime: '7:00 AM',
              endTime: '9:15 AM',
              duration: '7:00 AM - 9:15 AM',
              teacher: 'MANSILLA NEYRA, JUAN RAMON',
              locationCode: 'IND - TORRE A 60TA - 604',
              locationDetail: 'Torre A, Piso 6, Salón 604',
              history: _generateSampleHistory('REDES DE COMPUTADORAS', '7:00 AM', '9:15 AM'),
              classroomLatitude: -11.997100, // Coordenadas de ejemplo del salón
              classroomLongitude: -77.061400,
              classroomRadius: 10.0,
            ),
          ],
        );
        loading = false;
      });
      
      // Programar notificaciones push para todos los cursos (10 minutos antes)
      // Esperar un poco para asegurar que las notificaciones estén inicializadas
      await Future.delayed(const Duration(seconds: 2));
      
      // Verificar permisos antes de programar
      final hasPermissions = await NotificationService.checkNotificationPermissions();
      if (!hasPermissions) {
        print('⚠️ ADVERTENCIA: Las notificaciones no están habilitadas');
        print('💡 El usuario debe habilitar las notificaciones en Configuración > Apps > Senati GPS > Notificaciones');
      }
      
      // Programar una notificación de prueba en 10 segundos para verificar que funciona
      print('🧪 Programando notificación de prueba en 10 segundos...');
      await NotificationService.scheduleTestNotification(10);
      
      if (student != null && student!.coursesToday.isNotEmpty) {
        print('📚 Programando notificaciones para ${student!.coursesToday.length} cursos');
        await NotificationService.scheduleAllCourseNotifications(
          student!.coursesToday,
        );
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  bool pointInsideCampus(double lat, double lon) {
    int intersectCount = 0;

    for (int i = 0; i < campusPolygon.length - 1; i++) {
      final p1 = campusPolygon[i];
      final p2 = campusPolygon[i + 1];

      if (((p1.longitude > lon) != (p2.longitude > lon)) &&
          (lat <
              (p2.latitude - p1.latitude) *
                      (lon - p1.longitude) /
                      (p2.longitude - p1.longitude) +
                  p1.latitude)) {
        intersectCount++;
      }
    }

    return intersectCount % 2 == 1; // impar = dentro
  }

  Future<void> _updateLocation() async {
    try {
      // 1) Obtener posicion actual
      final pos = await LocationService.getCurrentLocation();

      // 2) Ver si está dentro del polígono del campus
      final dentro = pointInsideCampus(pos.longitude, pos.latitude);

      // 3) Actualizar texto en pantalla
      setState(() {
        campusStatus = dentro ? "Dentro del campus" : "Fuera del campus";
      });

      // 4) Guardar en Firestore en usuarios/<UID>
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userUid)
          .update({
            'lat': pos.latitude,
            'lon': pos.longitude,
            'estado': campusStatus,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print("ERROR GPS: $e");
    }
  }

  final Map<int, bool> _showMap =
      {}; // Para controlar qué curso muestra el mapa

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
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
    final weekdays = [
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

  Color _getCourseTypeColor(String type) {
    switch (type) {
      case 'Seminario':
        return const Color(0xFFFFE0B2); // Naranja claro
      case 'Clase':
        return const Color(0xFFB3E5FC); // Azul claro
      case 'Tecnológico':
        return const Color(0xFFE1BEE7); // Morado claro
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getCourseTypeTextColor(String type) {
    switch (type) {
      case 'Seminario':
        return const Color(0xFFE65100); // Naranja oscuro
      case 'Clase':
        return const Color(0xFF01579B); // Azul oscuro
      case 'Tecnológico':
        return const Color(0xFF4A148C); // Morado oscuro
      default:
        return const Color(0xFF424242);
    }
  }

  // Función para ordenar cursos por horario de inicio
  List<Course> _sortCoursesByTime(List<Course> courses) {
    final sortedCourses = List<Course>.from(courses);
    sortedCourses.sort((a, b) {
      final timeA = _parseTime(a.startTime);
      final timeB = _parseTime(b.startTime);
      
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1; // Los que no tienen horario van al final
      if (timeB == null) return -1;
      
      return timeA.compareTo(timeB); // Ordenar de más temprano a más tarde
    });
    return sortedCourses;
  }

  // Función para parsear tiempo de formato "7:00 AM" a DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      // Formato esperado: "7:00 AM" o "2:00 PM" (formato en inglés)
      final now = DateTime.now();
      
      // Parsear manualmente para mayor control
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) {
        throw FormatException('Formato incorrecto: $timeStr');
      }
      
      final timePart = parts[0]; // "7:00"
      final amPm = parts[1].toUpperCase(); // "AM" o "PM"
      
      final timeParts = timePart.split(':');
      if (timeParts.length != 2) {
        throw FormatException('Formato de hora incorrecto: $timePart');
      }
      
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Convertir a formato 24 horas
      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }
      
      // Crear DateTime con la fecha de hoy y la hora parseada
      final result = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      return result;
    } catch (e) {
      print('Error parseando tiempo: $timeStr - $e');
      return null;
    }
  }

  // Función para determinar el estado de un curso
  CourseStatusInfo _getCourseStatus(Course course) {
    final now = DateTime.now();
    final startTime = _parseTime(course.startTime);
    final endTime = _parseTime(course.endTime);

    if (startTime == null || endTime == null) {
      return CourseStatusInfo(
        status: CourseStatus.upcoming,
        label: 'Horario no disponible',
        color: Colors.grey,
        icon: Icons.help_outline,
      );
    }

    // Calcular diferencia en minutos
    final minutesUntilStart = startTime.difference(now).inMinutes;
    final minutesUntilEnd = endTime.difference(now).inMinutes;

    // Finalizado (verificar primero) - si ya pasó el horario de fin
    if (minutesUntilEnd <= 0) {
      return CourseStatusInfo(
        status: CourseStatus.finished,
        label: 'Finalizado',
        color: Colors.grey,
        icon: Icons.check_circle_outline,
      );
    }

    // Llegada tardía (pasó la hora de inicio pero aún no termina) - Prioridad
    // Se considera tardío si pasaron más de 5 minutos desde el inicio
    if (minutesUntilStart < -5 && minutesUntilEnd > 0) {
      return CourseStatusInfo(
        status: CourseStatus.late,
        label: 'Llegada tardía',
        color: Colors.red,
        icon: Icons.warning,
      );
    }

    // En curso (el curso ya empezó, dentro de los primeros 5 minutos o después)
    if (minutesUntilStart <= 0 && minutesUntilEnd > 0) {
      return CourseStatusInfo(
        status: CourseStatus.inProgress,
        label: 'En curso',
        color: Colors.green,
        icon: Icons.play_circle_outline,
      );
    }

    // Próximo curso (10 minutos antes)
    if (minutesUntilStart > 0 && minutesUntilStart <= 10) {
      return CourseStatusInfo(
        status: CourseStatus.soon,
        label: 'Próximo curso',
        color: Colors.orange,
        icon: Icons.notifications_active,
      );
    }

    // Próximo (más de 10 minutos)
    return CourseStatusInfo(
      status: CourseStatus.upcoming,
      label: 'Próximo',
      color: Colors.blue,
      icon: Icons.schedule,
    );
  }

  // Función para verificar si el alumno está dentro del salón
  bool _isInsideClassroom(double? currentLat, double? currentLon, Course course) {
    if (currentLat == null || currentLon == null) return false;
    if (course.classroomLatitude == null || course.classroomLongitude == null) return false;
    
    final distance = Geolocator.distanceBetween(
      currentLat,
      currentLon,
      course.classroomLatitude!,
      course.classroomLongitude!,
    );
    
    return distance <= (course.classroomRadius ?? 10.0);
  }

  // Función para validar el estado de asistencia basado en GPS
  AttendanceStatus _validateAttendanceStatus(Course course, double? currentLat, double? currentLon) {
    final now = DateTime.now();
    final startTime = _parseTime(course.startTime);
    final endTime = _parseTime(course.endTime);
    
    if (startTime == null || endTime == null) {
      return AttendanceStatus.absent; // Por defecto ausente si no hay horario
    }
    
    // Verificar si estamos dentro del horario del curso
    final isWithinSchedule = now.isAfter(startTime) && now.isBefore(endTime);
    final isAfterEnd = now.isAfter(endTime);
    
    // Si ya pasó el horario y nunca ingresó, es ausente
    if (isAfterEnd && _courseFirstEntryTime[course.name] == null) {
      return AttendanceStatus.absent;
    }
    
    // Si está dentro del horario o ya pasó pero ingresó
    if (isWithinSchedule || (isAfterEnd && _courseFirstEntryTime[course.name] != null)) {
      final isInside = _isInsideClassroom(currentLat, currentLon, course);
      
      if (isInside) {
        // Si es la primera vez que ingresa, registrar la hora
        if (_courseFirstEntryTime[course.name] == null) {
          _courseFirstEntryTime[course.name] = now;
          
          // Verificar si ingresó a tiempo o tarde
          if (now.isAfter(startTime.add(const Duration(minutes: 5)))) {
            // Ingresó después de 5 minutos del inicio = Tardanza
            return AttendanceStatus.late;
          } else {
            // Ingresó a tiempo = Presente
            return AttendanceStatus.present;
          }
        } else {
          // Ya ingresó antes, mantener el estado que tenía
          return _courseAttendanceStatus[course.name] ?? AttendanceStatus.present;
        }
      } else {
        // Si salió del salón, mantener el último estado registrado
        // (no puede cambiar si sale al baño)
        return _courseAttendanceStatus[course.name] ?? AttendanceStatus.absent;
      }
    }
    
    // Si aún no ha empezado el curso, mantener ausente por defecto
    return AttendanceStatus.absent;
  }

  // Función para verificar asistencia de todos los cursos activos
  Future<void> _checkCourseAttendance() async {
    if (student == null) return;
    
    try {
      final position = await LocationService.getCurrentLocation();
      final currentLat = position.latitude;
      final currentLon = position.longitude;
      
      for (var course in student!.coursesToday) {
        final status = _getCourseStatus(course);
        final isActive = status.status == CourseStatus.inProgress || 
                        status.status == CourseStatus.late ||
                        (status.status == CourseStatus.finished && 
                         _courseFirstEntryTime[course.name] != null);
        
        if (isActive || status.status == CourseStatus.soon) {
          final attendanceStatus = _validateAttendanceStatus(course, currentLat, currentLon);
          _courseAttendanceStatus[course.name] = attendanceStatus;
          
          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      // Si hay error al obtener ubicación, mantener estados actuales
      print('Error al verificar asistencia GPS: $e');
    }
  }

  // Función para obtener el estado de asistencia GPS de un curso
  AttendanceStatus _getCourseAttendanceStatus(Course course) {
    return _courseAttendanceStatus[course.name] ?? AttendanceStatus.absent;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Detección específica para Pixel 7 Pro (1440 x 3120, ~6.7")
    final isPixel7Pro =
        screenWidth >= 400 &&
        screenWidth <= 450 &&
        screenHeight >= 850 &&
        screenHeight <= 950;
    final isTablet = screenWidth > 600;

    // Optimización específica para Pixel 7 Pro
    final padding = isPixel7Pro ? 20.0 : (isTablet ? 24.0 : 16.0);
    final isLargePhone = isPixel7Pro || (screenWidth >= 400 && !isTablet);

    // 👇 Aquí manejamos los estados de carga y datos
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (student == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco en lugar de oscuro
      drawer: _buildDrawer(context, isLargePhone, isTablet),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Barra superior azul con información del estudiante
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1B38E3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0), // Sin bordes redondeados
                  bottomRight: Radius.circular(0),
                ),
              ),
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: isLargePhone ? 24 : (isTablet ? 28 : 20),
                bottom: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto de perfil + estado
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: isLargePhone ? 64 : (isTablet ? 70 : 60),
                        height: isLargePhone ? 64 : (isTablet ? 70 : 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 2),
                          image: student != null && student!.photoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(student!.photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (student == null || student!.photoUrl.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: isLargePhone ? 42 : (isTablet ? 45 : 40),
                                color: const Color(0xFF757575),
                              )
                            : null,
                      ),
                      // 🔥 ESTADO ABAJO DERECHA
                      Positioned(
                        bottom: -6,
                        right: -6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: campusStatus == "Dentro del campus"
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            campusStatus == "Dentro del campus"
                                ? "Presente"
                                : "Ausente",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: isLargePhone ? 14 : (isTablet ? 16 : 12)),
                  // Nombre, ID y Semestre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                student!.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isLargePhone
                                      ? 17
                                      : (isTablet ? 18 : 16),
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isLargePhone ? 8 : (isTablet ? 10 : 6)),
                            // Icono de menú (a la derecha, a la altura del nombre)
                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Transform.translate(
                                  offset: Offset(0, -2),
                                  child: Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isLargePhone ? 6 : (isTablet ? 8 : 5)),
                        Text(
                          'ID: ${student!.id}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isLargePhone
                                ? 14
                                : (isTablet ? 15 : 13),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: isLargePhone ? 8 : (isTablet ? 10 : 6)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student!.semester,
                            style: TextStyle(
                              color: const Color(0xFF1B38E3),
                              fontSize: isLargePhone
                                  ? 13
                                  : (isTablet ? 14 : 12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 800 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sección de Información Académica - Sin tarjeta flotante
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: isLargePhone ? 24 : (isTablet ? 28 : 20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título con icono
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: const Color(0xFF1B38E3),
                                  size: isLargePhone
                                      ? 26
                                      : (isTablet ? 28 : 24),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Información Académica',
                                  style: TextStyle(
                                    fontSize: isLargePhone
                                        ? 20
                                        : (isTablet ? 22 : 18),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: isLargePhone ? 22 : (isTablet ? 24 : 20),
                            ),
                            // Dirección Zonal
                            _buildInfoRow(
                              'Dirección Zonal',
                              student!.zonalAddress,
                              isLargePhone,
                              isTablet,
                            ),
                            SizedBox(
                              height: isLargePhone ? 18 : (isTablet ? 20 : 16),
                            ),
                            // Escuela
                            _buildInfoRow(
                              'Escuela',
                              student!.school,
                              isLargePhone,
                              isTablet,
                            ),
                            SizedBox(
                              height: isLargePhone ? 18 : (isTablet ? 20 : 16),
                            ),
                            // Carrera
                            _buildInfoRow(
                              'Carrera',
                              student!.career,
                              isLargePhone,
                              isTablet,
                            ),
                            SizedBox(
                              height: isLargePhone ? 18 : (isTablet ? 20 : 16),
                            ),
                            // Correo Institucional
                            _buildInfoRow(
                              'Correo Institucional',
                              student!.institutionalEmail,
                              isLargePhone,
                              isTablet,
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Divider(height: 1, thickness: 1, color: Colors.grey[300]),

                      SizedBox(
                        height: isLargePhone ? 24 : (isTablet ? 28 : 20),
                      ),

                      // Sección de Cursos Programados - Sin tarjeta flotante
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título con icono y fecha
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: const Color(0xFF1B38E3),
                                size: isLargePhone ? 26 : (isTablet ? 28 : 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cursos Programados Hoy',
                                style: TextStyle(
                                  fontSize: isLargePhone
                                      ? 20
                                      : (isTablet ? 22 : 18),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C2C),
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
                              color: const Color(0xFF757575),
                            ),
                          ),
                          SizedBox(
                            height: isLargePhone ? 22 : (isTablet ? 24 : 20),
                          ),
                          // Lista de cursos ordenados por horario
                          ..._sortCoursesByTime(student!.coursesToday).asMap().entries.map((entry) {
                            final index = entry.key;
                            final course = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLargePhone
                                    ? 18
                                    : (isTablet ? 20 : 16),
                              ),
                              child: _buildCourseCard(
                                course,
                                index,
                                isLargePhone,
                                isTablet,
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
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: const Color(0xFF1B38E3),
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
                                            color: const Color(0xFF424242),
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
                                    'Total de cursos hoy: ${student!.coursesToday.length}',
                                    style: TextStyle(
                                      fontSize: isLargePhone
                                          ? 14
                                          : (isTablet ? 15 : 13),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF424242),
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
          // Chatbot flotante con información del estudiante
          FloatingChatbot(
            studentData: student != null ? {
              'NameEstudent': student!.name,
              'IdEstudiante': student!.id,
              'Semestre': student!.semester,
              'Campus': student!.zonalAddress,
              'Escuela': student!.school,
              'Carrera': student!.career,
              'CorreoInstud': student!.institutionalEmail,
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isLargePhone,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C2C2C),
            ),
          ),
        ),
      ],
    );
  }

  // Función helper para obtener información del estado de asistencia
  AttendanceStatusInfo? _getAttendanceStatusInfo(Course course) {
    final history = course.history;
    if (history == null || history.records.isEmpty) return null;
    
    final lastRecord = history.lastRecord;
    if (lastRecord == null) return null;
    
    return AttendanceStatusInfo(
      status: lastRecord.status,
      date: lastRecord.date,
      startTime: lastRecord.startTime,
      endTime: lastRecord.endTime,
    );
  }

  Widget _buildCourseCard(
    Course course,
    int index,
    bool isLargePhone,
    bool isTablet,
  ) {
    final showMap = _showMap[index] ?? false;
    final statusInfo = _getCourseStatus(course);
    final isFinished = statusInfo.status == CourseStatus.finished;

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isFinished 
                ? const Color(0xFFBDBDBD) 
                : const Color(0xFFE0E0E0), 
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(isLargePhone ? 18 : (isTablet ? 20 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y etiquetas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        style: TextStyle(
                          fontSize: isLargePhone ? 17 : (isTablet ? 18 : 16),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Etiqueta de estado de asistencia GPS
                    _buildAttendanceStatusBadge(course, isLargePhone, isTablet),
                  ],
                ),
                // Etiqueta de estado del curso
                SizedBox(height: isLargePhone ? 10 : (isTablet ? 12 : 8)),
                Builder(
                  builder: (context) {
                    final statusInfo = _getCourseStatus(course);
                    // Solo mostrar etiquetas relevantes (próximo curso, tardío, en curso)
                    if (statusInfo.status == CourseStatus.soon ||
                        statusInfo.status == CourseStatus.late ||
                        statusInfo.status == CourseStatus.inProgress) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
                          vertical: isLargePhone ? 6 : (isTablet ? 7 : 5),
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.15),
                          border: Border.all(
                            color: statusInfo.color,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusInfo.icon,
                              size: isLargePhone ? 16 : (isTablet ? 17 : 15),
                              color: statusInfo.color,
                            ),
                            SizedBox(width: isLargePhone ? 6 : (isTablet ? 7 : 5)),
                            Text(
                              statusInfo.label,
                              style: TextStyle(
                                fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                                fontWeight: FontWeight.bold,
                                color: statusInfo.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            // Horario
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time,
                  size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                  color: const Color(0xFF757575),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horario',
                        style: TextStyle(
                          fontSize: isLargePhone ? 13.5 : (isTablet ? 14 : 13),
                          color: const Color(0xFF757575),
                        ),
                      ),
                      Text(
                        '${course.startTime} - ${course.endTime}',
                        style: TextStyle(
                          fontSize: isLargePhone ? 14.5 : (isTablet ? 15 : 14),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        'Duración: ${course.duration}',
                        style: TextStyle(
                          fontSize: isLargePhone ? 12.5 : (isTablet ? 13 : 12),
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            // Docente
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person,
                  size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                  color: const Color(0xFF757575),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Docente',
                        style: TextStyle(
                          fontSize: isLargePhone ? 13.5 : (isTablet ? 14 : 13),
                          color: const Color(0xFF757575),
                        ),
                      ),
                      Text(
                        course.teacher,
                        style: TextStyle(
                          fontSize: isLargePhone ? 14.5 : (isTablet ? 15 : 14),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            // Ubicación
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                  color: const Color(0xFF757575),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: isLargePhone ? 13.5 : (isTablet ? 14 : 13),
                          color: const Color(0xFF757575),
                        ),
                      ),
                      Text(
                        course.locationCode,
                        style: TextStyle(
                          fontSize: isLargePhone ? 14.5 : (isTablet ? 15 : 14),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        course.locationDetail,
                        style: TextStyle(
                          fontSize: isLargePhone ? 12.5 : (isTablet ? 13 : 12),
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            // Botón Ver/Ocultar Mapa (funciona incluso si el curso está finalizado)
            SizedBox(
              width: double.infinity,
              height: isLargePhone ? 48 : (isTablet ? 50 : 44),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap[index] = !showMap;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B38E3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(showMap ? Icons.arrow_upward : Icons.send),
                label: Text(
                  showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa',
                  style: TextStyle(
                    fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                  ),
                ),
              ),
            ),
            // Mapa (si está visible, funciona incluso si el curso está finalizado)
            if (showMap) ...[
              SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF5F5F5),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(
                        isLargePhone ? 14 : (isTablet ? 16 : 12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                            color: const Color(0xFF2C2C2C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.locationDetail,
                                  style: TextStyle(
                                    fontSize: isLargePhone
                                        ? 15
                                        : (isTablet ? 16 : 14),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                                Text(
                                  course.name,
                                  style: TextStyle(
                                    fontSize: isLargePhone
                                        ? 12.5
                                        : (isTablet ? 13 : 12),
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TowerMapViewer(
                      height: isLargePhone ? 220 : (isTablet ? 250 : 200),
                      showControls: true,
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        isLargePhone ? 14 : (isTablet ? 16 : 12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: isLargePhone ? 48 : (isTablet ? 50 : 44),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NavigationMapScreen(
                                  locationName: course.name,
                                  locationDetail: course.locationDetail,
                                  initialView: 'interior', // Por defecto mostrar vista interior para navegación
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D79FF), // Azul celeste igual que "Presente"
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.send),
                          label: Text(
                            'Navegar Ahora (Tiempo Real)',
                            style: TextStyle(
                              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
  }

  // Función para construir la etiqueta de estado de asistencia GPS
  Widget _buildAttendanceStatusBadge(
    Course course,
    bool isLargePhone,
    bool isTablet,
  ) {
    final attendanceStatus = _getCourseAttendanceStatus(course);
    final statusInfo = _getAttendanceBadgeInfo(attendanceStatus);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo.color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: isLargePhone ? 15 : (isTablet ? 16 : 14),
            color: statusInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: isLargePhone ? 12.5 : (isTablet ? 13 : 12),
              fontWeight: FontWeight.bold,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBadge(
    AttendanceStatus status,
    bool isLargePhone,
    bool isTablet,
  ) {
    final badgeInfo = _getAttendanceBadgeInfo(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 12 : (isTablet ? 14 : 10),
        vertical: isLargePhone ? 6 : (isTablet ? 7 : 5),
      ),
      decoration: BoxDecoration(
        color: badgeInfo.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeInfo.color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeInfo.icon,
            size: isLargePhone ? 16 : (isTablet ? 17 : 15),
            color: badgeInfo.color,
          ),
          SizedBox(width: isLargePhone ? 6 : (isTablet ? 7 : 5)),
          Text(
            badgeInfo.label,
            style: TextStyle(
              fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
              fontWeight: FontWeight.bold,
              color: badgeInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  AttendanceBadgeInfo _getAttendanceBadgeInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
      case AttendanceStatus.completed:
        return AttendanceBadgeInfo(
          label: status == AttendanceStatus.completed ? 'Completado' : 'Presente',
          color: const Color(0xFF3D79FF),
          icon: Icons.check_circle,
        );
      case AttendanceStatus.late:
        return AttendanceBadgeInfo(
          label: 'Tardanza',
          color: const Color(0xFF4864A2),
          icon: Icons.schedule,
        );
      case AttendanceStatus.absent:
        return AttendanceBadgeInfo(
          label: 'Ausente',
          color: const Color(0xFF622222),
          icon: Icons.cancel,
        );
    }
  }

  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  // Construir el drawer lateral moderno con fondo azul
  Widget _buildDrawer(BuildContext context, bool isLargePhone, bool isTablet) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B38E3),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header del drawer
              Container(
                padding: EdgeInsets.all(isLargePhone ? 20 : (isTablet ? 24 : 16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Menú',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargePhone ? 24 : (isTablet ? 26 : 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Separador
              Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              
              const SizedBox(height: 8),
              
              // Opciones del menú
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                    vertical: 8,
                  ),
                  children: [
                    // Botón Baños
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.wc,
                      title: 'Baños',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BathroomStatusScreen(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    
                    // Separador
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    
                    // Botón Cursos
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.folder,
                      title: 'Cursos',
                      onTap: () {
                        Navigator.pop(context);
                        if (student != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoursesListScreen(
                                courses: student!.coursesToday,
                              ),
                            ),
                          );
                        }
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    
                    // Separador
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    
                    // Botón Amigos
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people,
                      title: 'Amigos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsScreen(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    
                    // Separador
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    
                    // Botón Asistente Virtual (Chatbot)
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.smart_toy,
                      title: 'Asistente Virtual',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatbotScreen(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    
                    // Separador
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    
                    // Botón Administración de Salones
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.admin_panel_settings,
                      title: 'Administración de Salones',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalonesAdminScreen(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
              
              // Separador antes de cerrar sesión
              Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              
              const SizedBox(height: 8),
              
              // Botón Cerrar Sesión
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                  vertical: 8,
                ),
                child: _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _authService.logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al cerrar sesión: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  isLargePhone: isLargePhone,
                  isTablet: isTablet,
                  isLogout: true,
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Construir item del drawer moderno (sin botones, solo líneas)
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isLargePhone,
    required bool isTablet,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
          vertical: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red.shade300 : Colors.white,
              size: isLargePhone ? 24 : (isTablet ? 26 : 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isLogout ? Colors.red.shade300 : Colors.white,
                  fontSize: isLargePhone ? 16 : (isTablet ? 18 : 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isLogout ? Colors.red.shade300 : Colors.white.withOpacity(0.7),
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Clases helper para información de asistencia
class AttendanceStatusInfo {
  final AttendanceStatus status;
  final DateTime date;
  final String startTime;
  final String endTime;

  AttendanceStatusInfo({
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class AttendanceBadgeInfo {
  final String label;
  final Color color;
  final IconData icon;

  AttendanceBadgeInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
