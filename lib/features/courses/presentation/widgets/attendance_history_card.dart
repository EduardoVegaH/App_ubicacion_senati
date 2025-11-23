import 'package:flutter/material.dart';
import '../../../home/domain/entities/attendance_entity.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../../app/styles/app_spacing.dart';

/// Widget de tarjeta de historial de asistencia
class AttendanceHistoryCard extends StatelessWidget {
  final AttendanceRecordEntity record;

  const AttendanceHistoryCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    final statusInfo = _getStatusInfo(record.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: AppSpacing.cardPaddingSmall(isLargePhone, isTablet),
      child: Row(
        children: [
          // Icono circular de estado
          Container(
            width: isLargePhone ? 44 : (isTablet ? 48 : 40),
            height: isLargePhone ? 44 : (isTablet ? 48 : 40),
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusInfo.icon,
              color: statusInfo.color,
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
            ),
          ),
          SizedBox(width: isLargePhone ? 14 : (isTablet ? 16 : 12)),
          // Información del registro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha
                Text(
                  _formatDate(record.date),
                  style: AppTextStyles.bodyBoldMedium(isLargePhone, isTablet),
                ),
                const SizedBox(height: 4),
                // Hora
                Text(
                  '${record.startTime} - ${record.endTime}',
                  style: AppTextStyles.bodyMicro(isLargePhone, isTablet),
                ),
                const SizedBox(height: 8),
                // Badge de estado
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
                    vertical: isLargePhone ? 5 : (isTablet ? 6 : 4),
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusInfo.color,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: AppTextStyles.textWithColor(isLargePhone, isTablet, statusInfo.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return StatusInfo(
          label: 'Presente',
          color: const Color(0xFF3D79FF),
          icon: Icons.check_circle,
        );
      case AttendanceStatus.late:
        return StatusInfo(
          label: 'Tardanza',
          color: const Color(0xFF4864A2),
          icon: Icons.schedule,
        );
      case AttendanceStatus.absent:
        return StatusInfo(
          label: 'Ausente',
          color: const Color(0xFF622222),
          icon: Icons.cancel,
        );
      case AttendanceStatus.completed:
        return StatusInfo(
          label: 'Completado',
          color: const Color(0xFF3D79FF),
          icon: Icons.check_circle_outline,
        );
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

class StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

