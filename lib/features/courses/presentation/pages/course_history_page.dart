import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../../../core/widgets/empty_states/index.dart';
import '../../../home/data/models/student_model.dart';
import '../../../home/domain/entities/attendance_entity.dart';
import '../../../home/domain/use_cases/filter_and_sort_attendance_records_use_case.dart';
import '../../../home/presentation/widgets/info_banner.dart';
import '../widgets/attendance_history_card.dart';
import '../widgets/course_history_header.dart';

/// Página de historial de cursos
class CourseHistoryPage extends StatefulWidget {
  final CourseModel course;

  const CourseHistoryPage({
    super.key,
    required this.course,
  });

  @override
  State<CourseHistoryPage> createState() => _CourseHistoryPageState();
}

class _CourseHistoryPageState extends State<CourseHistoryPage> {
  AttendanceStatus? _selectedFilter; // null = todos, o un estado específico
  late final FilterAndSortAttendanceRecordsUseCase _filterAndSortUseCase;

  @override
  void initState() {
    super.initState();
    _filterAndSortUseCase = FilterAndSortAttendanceRecordsUseCase();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.course.history;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    if (history == null || history.records.isEmpty) {
      return Scaffold(
        appBar: const AppBarWithTitle(
          title: 'Historial de asistencias',
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: AppStyles.textOnDark,
        ),
        body: EmptyState(
          icon: Icons.history,
          message: 'No hay historial disponible',
        ),
      );
    }

    // Delegar filtrado y ordenamiento al use case
    final sortedRecords = _filterAndSortUseCase.call(
      records: history.records,
      filter: _selectedFilter,
    );

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: const AppBarWithTitle(
        title: 'Historial de asistencias',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: Column(
        children: [
          // Encabezado con nombre del curso y estadísticas compactas
          CourseHistoryHeader(
            courseName: widget.course.name,
            teacherName: widget.course.teacher,
            stats: CourseHistoryStats(
              totalSessions: history.totalSessions,
              totalPresent: history.totalPresent,
              totalLate: history.totalLate,
              totalAbsent: history.totalAbsent,
            ),
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),

          // Lista de registros
          Expanded(
            child: sortedRecords.isEmpty
                ? EmptyFilterState(
                    message: 'No hay registros con este filtro',
                    hint: 'Toca "Total" para ver todos los registros',
                    icon: Icons.filter_alt_off,
                  )
                : ListView.builder(
              padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
              itemCount: sortedRecords.length + 1, // +1 para el banner al final
              itemBuilder: (context, index) {
                // Si es el último item, mostrar el banner informativo
                if (index == sortedRecords.length) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: isLargePhone ? 16 : (isTablet ? 18 : 14),
                      bottom: isLargePhone ? 16 : (isTablet ? 18 : 14),
                    ),
                    child: InfoBanner(
                      icon: Icons.info_outline,
                      message: 'Este historial te permite verificar tus asistencias registradas automáticamente.',
                      iconColor: AppStyles.primaryColor,
                      backgroundColor: const Color(0xFFF5F5F5),
                      borderColor: const Color(0xFFE0E0E0),
                      textStyle: AppTextStyles.courseHistoryBanner(isLargePhone, isTablet),
                    ),
                  );
                }
                
                final record = sortedRecords[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLargePhone ? 10 : (isTablet ? 12 : 8),
                  ),
                  child: AttendanceHistoryCard(record: record),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

