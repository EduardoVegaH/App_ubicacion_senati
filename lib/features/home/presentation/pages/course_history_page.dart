import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../data/models/student_model.dart';
import '../../domain/entities/attendance_entity.dart';
import '../widgets/attendance_history_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final history = widget.course.history;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    if (history == null || history.records.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Historial de asistencias',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: AppStyles.textOnDark,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay historial disponible',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrar registros según el filtro seleccionado
    List<AttendanceRecordEntity> filteredRecords = history.records;
    if (_selectedFilter != null) {
      filteredRecords = history.records
          .where((record) => record.status == _selectedFilter)
          .toList();
    }

    // Ordenar registros por fecha (más recientes primero)
    final sortedRecords = List<AttendanceRecordEntity>.from(filteredRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Historial de asistencias',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: Column(
        children: [
          // Encabezado con nombre del curso y estadísticas compactas
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.name,
                  style: TextStyle(
                    fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Nombre del docente (subtítulo)
                Text(
                  widget.course.teacher,
                  style: TextStyle(
                    fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isLargePhone ? 12 : (isTablet ? 14 : 10)),
                // Estadísticas en una sola fila compacta (clicables)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = null; // Mostrar todos
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCompactStat(
                          'Total',
                          history.totalSessions.toString(),
                          _selectedFilter == null
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.25),
                          Colors.white,
                          isLargePhone,
                          isTablet,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = AttendanceStatus.present;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCompactStat(
                          'Presente',
                          history.totalPresent.toString(),
                          _selectedFilter == AttendanceStatus.present
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.25),
                          Colors.white,
                          isLargePhone,
                          isTablet,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = AttendanceStatus.late;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCompactStat(
                          'Tardanzas',
                          history.totalLate.toString(),
                          _selectedFilter == AttendanceStatus.late
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.25),
                          Colors.white,
                          isLargePhone,
                          isTablet,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = AttendanceStatus.absent;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCompactStat(
                          'Faltas',
                          history.totalAbsent.toString(),
                          _selectedFilter == AttendanceStatus.absent
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.25),
                          Colors.white,
                          isLargePhone,
                          isTablet,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de registros
          Expanded(
            child: sortedRecords.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isLargePhone ? 32 : (isTablet ? 40 : 24)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay registros con este filtro',
                            style: TextStyle(
                              fontSize: isLargePhone ? 16 : (isTablet ? 18 : 14),
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca "Total" para ver todos los registros',
                            style: TextStyle(
                              fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
              padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 20 : 14)),
              itemCount: sortedRecords.length + 1, // +1 para el banner al final
              itemBuilder: (context, index) {
                // Si es el último item, mostrar el banner informativo
                if (index == sortedRecords.length) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: isLargePhone ? 16 : (isTablet ? 18 : 14),
                      bottom: isLargePhone ? 16 : (isTablet ? 18 : 14),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF1B38E3),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Este historial te permite verificar tus asistencias registradas automáticamente.',
                              style: TextStyle(
                                fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                                color: const Color(0xFF424242),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCompactStat(
    String label,
    String value,
    Color backgroundColor,
    Color textColor,
    bool isLargePhone,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 8 : (isTablet ? 10 : 6),
        vertical: isLargePhone ? 10 : (isTablet ? 12 : 8),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isLargePhone ? 10 : (isTablet ? 11 : 9),
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

