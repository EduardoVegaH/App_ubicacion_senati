import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/course_status_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/use_cases/get_course_status_use_case.dart';
import '../../../navigation/presentation/pages/map_navigator_page.dart';

/// Widget de tarjeta de curso con diseño del código antiguo
class CourseCard extends StatefulWidget {
  final CourseEntity course;
  final int index;
  final AttendanceStatus? attendanceStatus;
  final GetCourseStatusUseCase? getCourseStatusUseCase;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    this.attendanceStatus,
    this.getCourseStatusUseCase,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _showMap = false;
  late GetCourseStatusUseCase _getCourseStatusUseCase;

  @override
  void initState() {
    super.initState();
    _getCourseStatusUseCase = widget.getCourseStatusUseCase ?? GetCourseStatusUseCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    final statusInfo = _getCourseStatusUseCase(widget.course);
    final isFinished = statusInfo.status == CourseStatus.finished;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isFinished ? const Color(0xFFBDBDBD) : const Color(0xFFE0E0E0),
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
                      widget.course.name,
                      style: TextStyle(
                        fontSize: isLargePhone ? 17 : (isTablet ? 18 : 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Etiqueta de estado de asistencia GPS
                  _buildAttendanceStatusBadge(isLargePhone, isTablet),
                ],
              ),
              // Etiqueta de estado del curso
              SizedBox(height: isLargePhone ? 10 : (isTablet ? 12 : 8)),
              Builder(
                builder: (context) {
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
                        color: _getCourseStatusColor(statusInfo.status).withOpacity(0.15),
                        border: Border.all(
                          color: _getCourseStatusColor(statusInfo.status),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCourseStatusIcon(statusInfo.status),
                            size: isLargePhone ? 16 : (isTablet ? 17 : 15),
                            color: _getCourseStatusColor(statusInfo.status),
                          ),
                          SizedBox(
                            width: isLargePhone ? 6 : (isTablet ? 7 : 5),
                          ),
                          Text(
                            statusInfo.label,
                            style: TextStyle(
                              fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                              fontWeight: FontWeight.bold,
                              color: _getCourseStatusColor(statusInfo.status),
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
                      '${widget.course.startTime} - ${widget.course.endTime}',
                      style: TextStyle(
                        fontSize: isLargePhone ? 14.5 : (isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      'Duración: ${widget.course.duration}',
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
                      widget.course.teacher,
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
                      widget.course.locationCode,
                      style: TextStyle(
                        fontSize: isLargePhone ? 14.5 : (isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      widget.course.locationDetail,
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
                  _showMap = !_showMap;
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
              icon: Icon(_showMap ? Icons.arrow_upward : Icons.send),
              label: Text(
                _showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa',
                style: TextStyle(
                  fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                ),
              ),
            ),
          ),
          // Mapa (si está visible)
          if (_showMap) ...[
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
                                widget.course.locationDetail,
                                style: TextStyle(
                                  fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              Text(
                                widget.course.name,
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
                  // Placeholder para el mapa (se puede reemplazar con TowerMapViewer si es necesario)
                  Container(
                    height: isLargePhone ? 220 : (isTablet ? 250 : 200),
                    color: const Color(0xFFF5F5F5),
                    child: Center(
                      child: Icon(
                        Icons.map,
                        size: 64,
                        color: Colors.grey[400],
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
                          // Extraer información del salón desde locationCode
                          // Formato esperado: "IND - TORRE B 60TB - 200"
                          final salonId = _extractSalonId(widget.course.locationCode);
                          final piso = _extractPiso(widget.course.locationDetail);
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MapNavigatorPage(
                                objetivoSalonId: salonId,
                                piso: piso,
                                salonNombre: widget.course.locationDetail,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D79FF),
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

  Widget _buildAttendanceStatusBadge(bool isLargePhone, bool isTablet) {
    final attendanceStatus = widget.attendanceStatus ?? AttendanceStatus.absent;
    final badgeInfo = _getAttendanceBadgeInfo(attendanceStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeInfo.color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeInfo.icon,
            size: isLargePhone ? 15 : (isTablet ? 16 : 14),
            color: badgeInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeInfo.label,
            style: TextStyle(
              fontSize: isLargePhone ? 12.5 : (isTablet ? 13 : 12),
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

  Color _getCourseStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.soon:
        return Colors.orange;
      case CourseStatus.late:
        return Colors.red;
      case CourseStatus.inProgress:
        return Colors.green;
      case CourseStatus.upcoming:
        return Colors.blue;
      case CourseStatus.finished:
        return Colors.grey;
    }
  }

  IconData _getCourseStatusIcon(CourseStatus status) {
    switch (status) {
      case CourseStatus.soon:
        return Icons.notifications_active;
      case CourseStatus.late:
        return Icons.warning;
      case CourseStatus.inProgress:
        return Icons.play_circle_outline;
      case CourseStatus.upcoming:
        return Icons.schedule;
      case CourseStatus.finished:
        return Icons.check_circle_outline;
    }
  }

  String _extractSalonId(String locationCode) {
    // Formato: "IND - TORRE B 60TB - 200"
    // Extraer "60TB-200" o similar
    final parts = locationCode.split(' - ');
    if (parts.length >= 3) {
      final salonPart = parts[2].trim();
      // Intentar extraer el código del salón
      return salonPart;
    }
    // Fallback: usar el código completo
    return locationCode;
  }

  int _extractPiso(String locationDetail) {
    // Formato: "Torre B, Piso 2, Salón 200"
    final pisoMatch = RegExp(r'Piso\s+(\d+)').firstMatch(locationDetail);
    if (pisoMatch != null) {
      return int.tryParse(pisoMatch.group(1) ?? '1') ?? 1;
    }
    return 1; // Default al piso 1
  }
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
