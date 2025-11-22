import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/course_status_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../../navigation/presentation/pages/map_navigator_page.dart';
import '../../../navigation/data/utils/salon_helper.dart';

/// Widget para la tarjeta de un curso
class CourseCard extends StatelessWidget {
  final CourseEntity course;
  final int index;
  final CourseStatusInfo statusInfo;
  final AttendanceStatus? attendanceStatus;
  final bool showMap;
  final Function(bool) onToggleMap;
  final bool isLargePhone;
  final bool isTablet;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.statusInfo,
    this.attendanceStatus,
    required this.showMap,
    required this.onToggleMap,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = statusInfo.status == CourseStatus.finished;

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        border: Border.all(
          color: isFinished ? Colors.grey[300]! : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusM),
      ),
      padding: EdgeInsets.all(isLargePhone ? 18 : (isTablet ? 20 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y etiquetas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del curso
                    Text(
                      course.name,
                      style: TextStyle(
                        fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
                        fontWeight: FontWeight.bold,
                        color: AppStyles.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Tipo de curso
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
                        vertical: isLargePhone ? 5 : (isTablet ? 6 : 4),
                      ),
                      decoration: BoxDecoration(
                        color: _getCourseTypeColor(course.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.type,
                        style: TextStyle(
                          fontSize: isLargePhone ? 11 : (isTablet ? 12 : 10),
                          fontWeight: FontWeight.bold,
                          color: _getCourseTypeTextColor(course.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de estado del curso
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
                  vertical: isLargePhone ? 6 : (isTablet ? 8 : 5),
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(statusInfo.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(statusInfo.status),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(statusInfo.status),
                      size: isLargePhone ? 14 : (isTablet ? 16 : 12),
                      color: _getStatusColor(statusInfo.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        fontSize: isLargePhone ? 11 : (isTablet ? 12 : 10),
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(statusInfo.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Información del curso
          _buildInfoRow(
            Icons.access_time,
            '${course.startTime} - ${course.endTime}',
            isLargePhone,
            isTablet,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person,
            course.teacher,
            isLargePhone,
            isTablet,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on,
            course.locationDetail,
            isLargePhone,
            isTablet,
          ),
          // Badge de asistencia GPS (si aplica)
          if (attendanceStatus != null && !isFinished) ...[
            const SizedBox(height: 12),
            _buildAttendanceBadge(attendanceStatus!, isLargePhone, isTablet),
          ],
          // Botón de navegación
          if (!isFinished) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final salonId = SalonHelper.extractSalonId(
                        course.locationDetail,
                        course.locationCode,
                      );
                      final piso = SalonHelper.extractPisoFromLocation(
                        course.locationDetail,
                        course.locationCode,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapNavigatorPage(
                            objetivoSalonId: salonId,
                            piso: piso,
                            salonNombre: course.locationDetail,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.directions,
                      size: isLargePhone ? 18 : (isTablet ? 20 : 16),
                    ),
                    label: Text(
                      'Navegar',
                      style: TextStyle(
                        fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                      ),
                    ),
                    style: AppStyles.elevatedButtonStyle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    bool isLargePhone,
    bool isTablet,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: isLargePhone ? 16 : (isTablet ? 18 : 14),
          color: AppStyles.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
              color: AppStyles.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceBadge(
    AttendanceStatus status,
    bool isLargePhone,
    bool isTablet,
  ) {
    final info = _getAttendanceInfo(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
        vertical: isLargePhone ? 6 : (isTablet ? 8 : 5),
      ),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: info.color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info.icon,
            size: isLargePhone ? 14 : (isTablet ? 16 : 12),
            color: info.color,
          ),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: TextStyle(
              fontSize: isLargePhone ? 11 : (isTablet ? 12 : 10),
              fontWeight: FontWeight.bold,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCourseTypeColor(String type) {
    switch (type) {
      case 'Seminario':
        return Colors.orange;
      case 'Clase':
        return Colors.blue;
      case 'Tecnológico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getCourseTypeTextColor(String type) {
    switch (type) {
      case 'Seminario':
        return Colors.orange.shade900;
      case 'Clase':
        return Colors.blue.shade900;
      case 'Tecnológico':
        return Colors.purple.shade900;
      default:
        return Colors.grey.shade900;
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
        return Icons.notifications;
      case CourseStatus.inProgress:
        return Icons.play_circle;
      case CourseStatus.late:
        return Icons.warning;
      case CourseStatus.finished:
        return Icons.check_circle;
    }
  }

  AttendanceInfo _getAttendanceInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AttendanceInfo(
          label: 'Presente',
          color: AppStyles.successColor,
          icon: Icons.check_circle,
        );
      case AttendanceStatus.late:
        return AttendanceInfo(
          label: 'Tardanza',
          color: AppStyles.warningColor,
          icon: Icons.schedule,
        );
      case AttendanceStatus.absent:
        return AttendanceInfo(
          label: 'Ausente',
          color: AppStyles.errorColor,
          icon: Icons.cancel,
        );
      case AttendanceStatus.completed:
        return AttendanceInfo(
          label: 'Completado',
          color: AppStyles.successColor,
          icon: Icons.check_circle_outline,
        );
    }
  }
}

class AttendanceInfo {
  final String label;
  final Color color;
  final IconData icon;

  AttendanceInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

