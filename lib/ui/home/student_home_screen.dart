import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/student_model.dart';
import '../login/qr_scan_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // Datos de ejemplo del estudiante
  final Student student = Student(
    name: 'SEBASTIAN RICARDO EFREN LAN',
    id: '001596669',
    semester: '5to Semestre',
    photoUrl: '', // Se usará un placeholder
    zonalAddress: 'Independencia',
    school: 'ETI - Escuela de Tecnologías e Información',
    career: 'Desarrollo de Software',
    institutionalEmail: '1596669@senati.pe',
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

  final Map<int, bool> _showMap = {}; // Para controlar qué curso muestra el mapa

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // Detección específica para Pixel 7 Pro (1440 x 3120, ~6.7")
    // En densidad lógica, esto es aproximadamente 412 x 892 dp
    final isPixel7Pro = screenWidth >= 400 && screenWidth <= 450 && 
                        screenHeight >= 850 && screenHeight <= 950;
    final isTablet = screenWidth > 600;
    
    // Optimización específica para Pixel 7 Pro
    final padding = isPixel7Pro ? 20.0 : (isTablet ? 24.0 : 16.0);
    final isLargePhone = isPixel7Pro || (screenWidth >= 400 && !isTablet);
    
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco en lugar de oscuro
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior azul con información del estudiante
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
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
                            const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                      const Icon(Icons.visibility, color: Colors.white, size: 20),
                    ],
                  ),
                  SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                  // Información del estudiante
                  Row(
                    children: [
                      // Foto de perfil
                      Container(
                        width: isLargePhone ? 64 : (isTablet ? 70 : 60),
                        height: isLargePhone ? 64 : (isTablet ? 70 : 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: isLargePhone ? 42 : (isTablet ? 45 : 40),
                          color: const Color(0xFF757575),
                        ),
                      ),
                      SizedBox(width: isLargePhone ? 14 : (isTablet ? 16 : 12)),
                      // Nombre, ID y Semestre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargePhone ? 17 : (isTablet ? 18 : 16),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${student.id}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                student.semester,
                                style: TextStyle(
                                  color: const Color(0xFF1976D2),
                                  fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
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
                        padding: EdgeInsets.only(bottom: isLargePhone ? 24 : (isTablet ? 28 : 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título con icono
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: const Color(0xFF1976D2),
                                  size: isLargePhone ? 26 : (isTablet ? 28 : 24),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Información Académica',
                                  style: TextStyle(
                                    fontSize: isLargePhone ? 20 : (isTablet ? 22 : 18),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isLargePhone ? 22 : (isTablet ? 24 : 20)),
                            // Dirección Zonal
                            _buildInfoRow('Dirección Zonal', student.zonalAddress, isLargePhone, isTablet),
                            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                            // Escuela
                            _buildInfoRow('Escuela', student.school, isLargePhone, isTablet),
                            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                            // Carrera
                            _buildInfoRow('Carrera', student.career, isLargePhone, isTablet),
                            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                            // Correo Institucional
                            _buildInfoRow('Correo Institucional', student.institutionalEmail, isLargePhone, isTablet),
                          ],
                        ),
                      ),

                      // Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),

                      SizedBox(height: isLargePhone ? 24 : (isTablet ? 28 : 20)),

                      // Sección de Cursos Programados - Sin tarjeta flotante
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título con icono y fecha
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: const Color(0xFF1976D2),
                                size: isLargePhone ? 26 : (isTablet ? 28 : 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cursos Programados Hoy',
                                style: TextStyle(
                                  fontSize: isLargePhone ? 20 : (isTablet ? 22 : 18),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isLargePhone ? 10 : (isTablet ? 12 : 8)),
                          Text(
                            _getCurrentDate(),
                            style: TextStyle(
                              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                              color: const Color(0xFF757575),
                            ),
                          ),
                          SizedBox(height: isLargePhone ? 22 : (isTablet ? 24 : 20)),
                          // Lista de cursos
                          ...student.coursesToday.asMap().entries.map((entry) {
                            final index = entry.key;
                            final course = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                              child: _buildCourseCard(course, index, isLargePhone, isTablet),
                            );
                          }),
                          // Información adicional
                          Padding(
                            padding: EdgeInsets.only(top: isLargePhone ? 18 : (isTablet ? 20 : 16)),
                            child: Container(
                              padding: EdgeInsets.all(isLargePhone ? 18 : (isTablet ? 20 : 16)),
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
                                        color: const Color(0xFF1976D2),
                                        size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Presiona el botón "Ver Ubicación en Mapa" en cada curso para navegar al salón',
                                          style: TextStyle(
                                            fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                                            color: const Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isLargePhone ? 10 : (isTablet ? 12 : 8)),
                                  Text(
                                    'Total de cursos hoy: ${student.coursesToday.length}',
                                    style: TextStyle(
                                      fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
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

  Widget _buildInfoRow(String label, String value, bool isLargePhone, bool isTablet) {
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

  Widget _buildCourseCard(Course course, int index, bool isLargePhone, bool isTablet) {
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
                    Icon(Icons.book, size: isLargePhone ? 15 : (isTablet ? 16 : 14), color: const Color(0xFF424242)),
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
              Icon(Icons.access_time, size: isLargePhone ? 21 : (isTablet ? 22 : 20), color: const Color(0xFF757575)),
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
              Icon(Icons.person, size: isLargePhone ? 21 : (isTablet ? 22 : 20), color: const Color(0xFF757575)),
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
              Icon(Icons.location_on, size: isLargePhone ? 21 : (isTablet ? 22 : 20), color: const Color(0xFF757575)),
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
                backgroundColor: const Color(0xFF1976D2),
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
                    padding: EdgeInsets.all(isLargePhone ? 14 : (isTablet ? 16 : 12)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: isLargePhone ? 21 : (isTablet ? 22 : 20), color: const Color(0xFF2C2C2C)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.locationDetail,
                                style: TextStyle(
                                  fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              Text(
                                course.name,
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
                    padding: EdgeInsets.all(isLargePhone ? 14 : (isTablet ? 16 : 12)),
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

// Painter para el logo "S" pequeño en la barra superior (si se necesita)
class _SmallStyledSPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    final path1 = Path();
    path1.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.6);
    path1.cubicTo(
      center.dx - radius * 0.4,
      center.dy - radius * 0.9,
      center.dx + radius * 0.1,
      center.dy - radius * 0.9,
      center.dx + radius * 0.4,
      center.dy - radius * 0.6,
    );
    path1.cubicTo(
      center.dx + radius * 0.65,
      center.dy - radius * 0.3,
      center.dx + radius * 0.65,
      center.dy,
      center.dx + radius * 0.4,
      center.dy + radius * 0.2,
    );

    final path2 = Path();
    path2.moveTo(center.dx + radius * 0.7, center.dy + radius * 0.6);
    path2.cubicTo(
      center.dx + radius * 0.4,
      center.dy + radius * 0.9,
      center.dx - radius * 0.1,
      center.dy + radius * 0.9,
      center.dx - radius * 0.4,
      center.dy + radius * 0.6,
    );
    path2.cubicTo(
      center.dx - radius * 0.65,
      center.dy + radius * 0.3,
      center.dx - radius * 0.65,
      center.dy,
      center.dx - radius * 0.4,
      center.dy - radius * 0.2,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

