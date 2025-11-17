import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../login/qr_scan_screen.dart';
import '../../services/firebase_service.dart';
import 'dart:async'; // Tiempo de espera
import 'package:cloud_firestore/cloud_firestore.dart'; // firestore
import 'package:firebase_auth/firebase_auth.dart'; // firebase auth
import 'package:flutter_application_1/services/location_service.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
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

  //Polígono aproximado del campus SENATI INDEPENDENCIA
  final List<LatLng> campusPolygon = const [
    LatLng(-11.997005, -77.061355),
    LatLng(-11.997510, -77.061050),
    LatLng(-11.997950, -77.061660),
    LatLng(-11.997430, -77.061950),
  ];

  @override
  void initState() {
    super.initState();
    //1) Obtiene el UID del usuario logueado
    userUid = FirebaseAuth.instance.currentUser!.uid;
    // 2) Carga los datos del estudiante
    _loadStudentData();
    // 3) Activar el GPS automático cada 5 segundos
    gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateLocation();
    });
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
            ),
            Course(
              name: 'SEMINARIO COMPLEMENT PRÁCTI',
              type: 'Seminario',
              startTime: '10:15 AM',
              endTime: '1:15 PM',
              duration: '10:15 AM - 1:15 PM',
              teacher: 'MANSILLA NEYRA, JUAN RAMON',
              locationCode: 'IND - TORRE B 60TB - 200',
              locationDetail: 'Torre B, Piso 2, Salón 200',
            ),
            Course(
              name: 'DESARROLLO HUMANO',
              type: 'Clase',
              startTime: '2:00 PM',
              endTime: '3:30 PM',
              duration: '2:00 PM - 3:30 PM',
              teacher: 'GONZALES LEON, JACQUELINE CORAL',
              locationCode: 'IND - TORRE C 60TC - 604',
              locationDetail: 'Torre C, Piso 6, Salón 604',
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
            ),
          ],
        );
        loading = false;
      });
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

  @override
  void dispose() {
    gpsTimer?.cancel();
    super.dispose();
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
      body: SafeArea(
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
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Volver a escanear
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const QRScanScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Volver a escanear',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icono de ojo/privacidad
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                  // Información del estudiante
                  Row(
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
                                  : null, // Si no hay foto, se mostrará el ícono de persona
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
                          children: [
                            Text(
                              student!.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargePhone
                                    ? 17
                                    : (isTablet ? 18 : 16),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${student!.id}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isLargePhone
                                    ? 14
                                    : (isTablet ? 15 : 13),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                          // Lista de cursos
                          ...student!.coursesToday.asMap().entries.map((entry) {
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

  Widget _buildCourseCard(
    Course course,
    int index,
    bool isLargePhone,
    bool isTablet,
  ) {
    final showMap = _showMap[index] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(isLargePhone ? 18 : (isTablet ? 20 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y etiqueta
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCourseTypeColor(course.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.book,
                      size: isLargePhone ? 15 : (isTablet ? 16 : 14),
                      color: const Color(0xFF424242),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.type,
                      style: TextStyle(
                        fontSize: isLargePhone ? 12.5 : (isTablet ? 13 : 12),
                        fontWeight: FontWeight.bold,
                        color: _getCourseTypeTextColor(course.type),
                      ),
                    ),
                  ],
                ),
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
          // Botón Ver/Ocultar Mapa
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
          // Mapa (si está visible)
          if (showMap) ...[
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            Container(
              height: isLargePhone ? 220 : (isTablet ? 250 : 200),
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
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Mapa de Google Maps\n(Integración pendiente)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF757575),
                            fontSize: isLargePhone ? 13 : 12,
                          ),
                        ),
                      ),
                    ),
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
                          // TODO: Implementar navegación con Google Maps
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
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
}
