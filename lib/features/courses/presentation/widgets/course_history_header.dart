import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_shadows.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/stat_card/stat_card.dart';
import '../../../home/domain/entities/attendance_entity.dart';

/// Encabezado del historial de curso con nombre, docente y estadísticas
class CourseHistoryHeader extends StatelessWidget {
  /// Nombre del curso
  final String courseName;
  
  /// Nombre del docente
  final String teacherName;
  
  /// Estadísticas del historial
  final CourseHistoryStats stats;
  
  /// Filtro seleccionado actualmente
  final AttendanceStatus? selectedFilter;
  
  /// Callback cuando cambia el filtro
  final Function(AttendanceStatus?) onFilterChanged;

  const CourseHistoryHeader({
    super.key,
    required this.courseName,
    required this.teacherName,
    required this.stats,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor,
        boxShadow: AppShadows.headerShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del curso
          Text(
            courseName,
            style: AppTextStyles.courseHistoryTitle(isLargePhone, isTablet),
          ),
          const SizedBox(height: 4),
          // Nombre del docente
          Text(
            teacherName,
            style: AppTextStyles.courseHistoryTeacher(isLargePhone, isTablet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isLargePhone ? 12 : (isTablet ? 14 : 10)),
          // Estadísticas en una sola fila compacta (clicables)
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total',
                  value: stats.totalSessions.toString(),
                  backgroundColor: selectedFilter == null
                      ? AppStyles.whiteOverlayStrong
                      : AppStyles.whiteOverlayLight,
                  textColor: Colors.white,
                  onTap: () => onFilterChanged(null),
                  isSelected: selectedFilter == null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Presente',
                  value: stats.totalPresent.toString(),
                  backgroundColor: selectedFilter == AttendanceStatus.present
                      ? AppStyles.whiteOverlayStrong
                      : AppStyles.whiteOverlayLight,
                  textColor: Colors.white,
                  onTap: () => onFilterChanged(AttendanceStatus.present),
                  isSelected: selectedFilter == AttendanceStatus.present,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Tardanzas',
                  value: stats.totalLate.toString(),
                  backgroundColor: selectedFilter == AttendanceStatus.late
                      ? AppStyles.whiteOverlayStrong
                      : AppStyles.whiteOverlayLight,
                  textColor: Colors.white,
                  onTap: () => onFilterChanged(AttendanceStatus.late),
                  isSelected: selectedFilter == AttendanceStatus.late,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Faltas',
                  value: stats.totalAbsent.toString(),
                  backgroundColor: selectedFilter == AttendanceStatus.absent
                      ? AppStyles.whiteOverlayStrong
                      : AppStyles.whiteOverlayLight,
                  textColor: Colors.white,
                  onTap: () => onFilterChanged(AttendanceStatus.absent),
                  isSelected: selectedFilter == AttendanceStatus.absent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modelo de estadísticas del historial de curso
class CourseHistoryStats {
  final int totalSessions;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;

  CourseHistoryStats({
    required this.totalSessions,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
  });
}

