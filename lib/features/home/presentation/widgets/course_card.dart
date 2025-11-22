import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/course_status_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../../navigation/presentation/pages/map_navigator_page.dart';
import '../../../navigation/data/utils/salon_helper.dart';
import '../../../../core/widgets/index.dart';

/// Widget para la tarjeta de un curso (diseño basado en el original)
class CourseCard extends StatefulWidget {
  final CourseEntity course;
  final int index;
  final CourseStatusInfo statusInfo;
  final AttendanceStatus? attendanceStatus;
  final bool isLargePhone;
  final bool isTablet;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.statusInfo,
    this.attendanceStatus,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.statusInfo.status == CourseStatus.finished;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isFinished ? const Color(0xFFBDBDBD) : AppStyles.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(
        widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
      ),
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
                        fontSize: widget.isLargePhone
                            ? 17
                            : (widget.isTablet ? 18 : 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Etiqueta de estado de asistencia GPS
                  _buildAttendanceStatusBadge(),
                ],
              ),
              // Etiqueta de estado del curso
              SizedBox(
                height: widget.isLargePhone ? 10 : (widget.isTablet ? 12 : 8),
              ),
              Builder(
                builder: (context) {
                  // Solo mostrar etiquetas relevantes (próximo curso, tardío, en curso)
                  if (widget.statusInfo.status == CourseStatus.soon ||
                      widget.statusInfo.status == CourseStatus.late ||
                      widget.statusInfo.status == CourseStatus.inProgress) {
                    final statusColor = _getStatusColor(widget.statusInfo.status);
                    final statusIcon = _getStatusIcon(widget.statusInfo.status);
                    
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isLargePhone
                            ? 10
                            : (widget.isTablet ? 12 : 8),
                        vertical: widget.isLargePhone ? 6 : (widget.isTablet ? 7 : 5),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        border: Border.all(
                          color: statusColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: widget.isLargePhone
                                ? 16
                                : (widget.isTablet ? 17 : 15),
                            color: statusColor,
                          ),
                          SizedBox(
                            width: widget.isLargePhone ? 6 : (widget.isTablet ? 7 : 5),
                          ),
                          Text(
                            widget.statusInfo.label,
                            style: TextStyle(
                              fontSize: widget.isLargePhone
                                  ? 13
                                  : (widget.isTablet ? 14 : 12),
                              fontWeight: FontWeight.bold,
                              color: statusColor,
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
          SizedBox(
            height: widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
          ),
          // Horario
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.access_time,
                size: widget.isLargePhone ? 21 : (widget.isTablet ? 22 : 20),
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horario',
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 13.5
                            : (widget.isTablet ? 14 : 13),
                        color: AppStyles.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.course.startTime} - ${widget.course.endTime}',
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 14.5
                            : (widget.isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      'Duración: ${widget.course.duration}',
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 12.5
                            : (widget.isTablet ? 13 : 12),
                        color: AppStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
          ),
          // Docente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.person,
                size: widget.isLargePhone ? 21 : (widget.isTablet ? 22 : 20),
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Docente',
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 13.5
                            : (widget.isTablet ? 14 : 13),
                        color: AppStyles.textSecondary,
                      ),
                    ),
                    Text(
                      widget.course.teacher,
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 14.5
                            : (widget.isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
          ),
          // Ubicación
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: widget.isLargePhone ? 21 : (widget.isTablet ? 22 : 20),
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación',
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 13.5
                            : (widget.isTablet ? 14 : 13),
                        color: AppStyles.textSecondary,
                      ),
                    ),
                    Text(
                      widget.course.locationCode,
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 14.5
                            : (widget.isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      widget.course.locationDetail,
                      style: TextStyle(
                        fontSize: widget.isLargePhone
                            ? 12.5
                            : (widget.isTablet ? 13 : 12),
                        color: AppStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
          ),
          // Botón Ver/Ocultar Mapa
          SizedBox(
            width: double.infinity,
            height: widget.isLargePhone ? 48 : (widget.isTablet ? 50 : 44),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showMap = !_showMap;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
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
                  fontSize: widget.isLargePhone ? 15 : (widget.isTablet ? 16 : 14),
                ),
              ),
            ),
          ),
          // Mapa (si está visible)
          if (_showMap) ...[
            SizedBox(
              height: widget.isLargePhone ? 18 : (widget.isTablet ? 20 : 16),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppStyles.borderColor),
                borderRadius: BorderRadius.circular(12),
                color: AppStyles.lightGrayBackground,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      widget.isLargePhone ? 14 : (widget.isTablet ? 16 : 12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: widget.isLargePhone ? 21 : (widget.isTablet ? 22 : 20),
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
                                  fontSize: widget.isLargePhone
                                      ? 15
                                      : (widget.isTablet ? 16 : 14),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                              Text(
                                widget.course.name,
                                style: TextStyle(
                                  fontSize: widget.isLargePhone
                                      ? 12.5
                                      : (widget.isTablet ? 13 : 12),
                                  color: AppStyles.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TowerMapViewer(
                    height: widget.isLargePhone ? 220 : (widget.isTablet ? 250 : 200),
                    showControls: true,
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      widget.isLargePhone ? 14 : (widget.isTablet ? 16 : 12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: widget.isLargePhone ? 48 : (widget.isTablet ? 50 : 44),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final salonId = SalonHelper.extractSalonId(
                            widget.course.locationDetail,
                            widget.course.locationCode,
                          );
                          final piso = SalonHelper.extractPisoFromLocation(
                            widget.course.locationDetail,
                            widget.course.locationCode,
                          );
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
                            fontSize: widget.isLargePhone ? 15 : (widget.isTablet ? 16 : 14),
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

  Widget _buildAttendanceStatusBadge() {
    if (widget.attendanceStatus == null) {
      return const SizedBox.shrink();
    }

    final badgeInfo = _getAttendanceBadgeInfo(widget.attendanceStatus!);

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
            size: widget.isLargePhone ? 15 : (widget.isTablet ? 16 : 14),
            color: badgeInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeInfo.label,
            style: TextStyle(
              fontSize: widget.isLargePhone ? 12.5 : (widget.isTablet ? 13 : 12),
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
          label: status == AttendanceStatus.completed
              ? 'Completado'
              : 'Presente',
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

  Color _getStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.upcoming:
        return AppStyles.primaryColor;
      case CourseStatus.soon:
        return AppStyles.warningColor;
      case CourseStatus.inProgress:
        return AppStyles.successColor;
      case CourseStatus.late:
        return AppStyles.errorColor;
      case CourseStatus.finished:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CourseStatus status) {
    switch (status) {
      case CourseStatus.upcoming:
        return Icons.schedule;
      case CourseStatus.soon:
        return Icons.notifications_active;
      case CourseStatus.inProgress:
        return Icons.play_circle_outline;
      case CourseStatus.late:
        return Icons.warning;
      case CourseStatus.finished:
        return Icons.check_circle_outline;
    }
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
