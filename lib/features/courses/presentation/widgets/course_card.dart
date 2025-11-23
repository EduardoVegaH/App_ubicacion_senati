import 'package:flutter/material.dart';
import '../../../home/domain/entities/student_entity.dart';
import '../../../home/domain/entities/course_status_entity.dart';
import '../../../home/domain/entities/attendance_entity.dart';
import '../../../home/domain/use_cases/get_course_status_use_case.dart';
import '../../../navigation/presentation/index.dart';
import '../../../../core/widgets/primary_button/primary_button.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../core/widgets/status_badge/status_badge.dart';

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
          color: isFinished ? AppStyles.greyMedium : AppStyles.greyLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: AppSpacing.cardPaddingLarge(isLargePhone, isTablet),
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
                      style: AppTextStyles.titleSmall(isLargePhone, isTablet),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Etiqueta de estado de asistencia GPS
                  _buildAttendanceStatusBadge(),
                ],
              ),
              // Etiqueta de estado del curso
              SizedBox(height: isLargePhone ? 10 : (isTablet ? 12 : 8)),
              _buildCourseStatusBadge(statusInfo, isLargePhone, isTablet),
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
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horario',
                      style: AppTextStyles.courseCardLabel(isLargePhone, isTablet),
                    ),
                    Text(
                      '${widget.course.startTime} - ${widget.course.endTime}',
                      style: AppTextStyles.courseCardValue(isLargePhone, isTablet),
                    ),
                    Text(
                      'Duración: ${widget.course.duration}',
                      style: AppTextStyles.courseCardSmall(isLargePhone, isTablet),
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
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Docente',
                      style: AppTextStyles.courseCardLabel(isLargePhone, isTablet),
                    ),
                    Text(
                      widget.course.teacher,
                      style: AppTextStyles.courseCardValue(isLargePhone, isTablet),
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
                color: AppStyles.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación',
                      style: AppTextStyles.courseCardLabel(isLargePhone, isTablet),
                    ),
                    Text(
                      widget.course.locationCode,
                      style: AppTextStyles.courseCardValue(isLargePhone, isTablet),
                    ),
                    Text(
                      widget.course.locationDetail,
                      style: AppTextStyles.courseCardSmall(isLargePhone, isTablet),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
          // Botón Ver/Ocultar Mapa
          PrimaryButton(
            label: _showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa',
            icon: _showMap ? Icons.arrow_upward : Icons.send,
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            variant: PrimaryButtonVariant.primary,
          ),
          // Mapa (si está visible)
          if (_showMap) ...[
            SizedBox(height: isLargePhone ? 18 : (isTablet ? 20 : 16)),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppStyles.greyLight),
                borderRadius: BorderRadius.circular(12),
                color: AppStyles.lightGrayBackground,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: AppSpacing.cardPaddingSmall(isLargePhone, isTablet),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: isLargePhone ? 21 : (isTablet ? 22 : 20),
                          color: AppStyles.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.locationDetail,
                                style: AppTextStyles.bodyBoldMedium(isLargePhone, isTablet),
                              ),
                              Text(
                                widget.course.name,
                                style: AppTextStyles.courseCardSmall(isLargePhone, isTablet),
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
                    color: AppStyles.lightGrayBackground,
                    child: Center(
                      child: Icon(
                        Icons.map,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.cardPaddingSmall(isLargePhone, isTablet),
                    child: PrimaryButton(
                      label: 'Navegar Ahora (Tiempo Real)',
                      icon: Icons.send,
                      onPressed: () {
                        // Extraer información del salón desde locationCode
                        // Formato esperado: "IND - TORRE B 60TB - 200"
                        final salonId = _extractSalonId(widget.course.locationCode);
                        final piso = _extractPiso(widget.course.locationDetail);
                        
                        // Mapear salón a nodo de destino
                        // Por ahora, usar un formato simple: node_puerta_main01 como origen
                        // y buscar el nodo del salón como destino
                        String toNodeId;
                        if (piso == 1) {
                          // Para piso 1, buscar nodo del salón
                          // Si el salón contiene "sal" o "A200", etc., buscar nodo correspondiente
                          toNodeId = _findNodeIdForSalon(salonId, piso);
                        } else if (piso == 2) {
                          // Para piso 2, buscar nodo del salón
                          toNodeId = _findNodeIdForSalon(salonId, piso);
                        } else {
                          // Piso por defecto
                          toNodeId = _findNodeIdForSalon(salonId, 1);
                        }
                        
                        // Nodo de origen: entrada principal del piso
                        // Para piso 1: usar node_puerta_main01 (entrada principal)
                        // Para piso 2: usar node#37 (nodo que está en la configuración de edges)
                        // Si estos nodos no existen, el error mostrará qué nodos están disponibles
                        final fromNodeId = piso == 1 
                            ? 'node_puerta_main01' 
                            : (piso == 2 ? 'node#37' : 'node_puerta_main01');
                        
                        print('🧭 Navegando: piso $piso, desde $fromNodeId hasta $toNodeId (salón: $salonId)');
                        print('⚠️ Si falla, verifica que los nodos existan en Firestore: /mapas/piso_$piso/nodes/');
                        
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => buildNavigationForRoom(
                              floor: piso > 0 ? piso : 1,
                              fromNodeId: fromNodeId,
                              toNodeId: toNodeId,
                            ),
                          ),
                        );
                      },
                      variant: PrimaryButtonVariant.secondary,
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
    final attendanceStatus = widget.attendanceStatus ?? AttendanceStatus.absent;
    final badgeInfo = _getAttendanceBadgeInfo(attendanceStatus);

    return StatusBadge(
      label: badgeInfo.label,
      color: badgeInfo.color,
      icon: badgeInfo.icon,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: 12,
    );
  }

  Widget _buildCourseStatusBadge(CourseStatusInfo statusInfo, bool isLargePhone, bool isTablet) {
    // Solo mostrar etiquetas relevantes (próximo curso, tardío, en curso)
    if (statusInfo.status == CourseStatus.soon ||
        statusInfo.status == CourseStatus.late ||
        statusInfo.status == CourseStatus.inProgress) {
      return StatusBadge(
        label: statusInfo.label,
        color: _getCourseStatusColor(statusInfo.status),
        icon: _getCourseStatusIcon(statusInfo.status),
      );
    }
    return const SizedBox.shrink();
  }

  AttendanceBadgeInfo _getAttendanceBadgeInfo(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
      case AttendanceStatus.completed:
        return AttendanceBadgeInfo(
          label: status == AttendanceStatus.completed ? 'Completado' : 'Presente',
          color: AppStyles.successColor,
          icon: Icons.check_circle,
        );
      case AttendanceStatus.late:
        return AttendanceBadgeInfo(
          label: 'Tardanza',
          color: AppStyles.lateColor,
          icon: Icons.schedule,
        );
      case AttendanceStatus.absent:
        return AttendanceBadgeInfo(
          label: 'Ausente',
          color: AppStyles.errorColor,
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

  /// Encuentra el ID del nodo correspondiente a un salón
  /// 
  /// Por ahora, usa una lógica simple basada en el número del salón
  String _findNodeIdForSalon(String salonId, int piso) {
    // Extraer número del salón (ej: "200" de "A200" o "60TB-200")
    final numberMatch = RegExp(r'(\d+)').firstMatch(salonId);
    final salonNumber = numberMatch?.group(1) ?? '';
    
    if (piso == 1) {
      // Para piso 1, buscar nodos que contengan el número
      // Por ahora, usar un nodo genérico si no encontramos uno específico
      if (salonNumber.isNotEmpty) {
        // Buscar nodo que contenga el número del salón
        // Los nodos de salones en piso 1 pueden tener formato como "node_puerta_..."
        return 'node_32'; // Nodo genérico del piso 1
      }
      return 'node_32';
    } else if (piso == 2) {
      // Para piso 2, buscar nodos con formato "node#XX_sal#A200"
      if (salonNumber.isNotEmpty) {
        // Buscar nodo que contenga el número del salón
        // Ejemplo: "node#34_sal#A200" para salón A200
        final letterMatch = RegExp(r'([A-Z])').firstMatch(salonId);
        final letter = letterMatch?.group(1) ?? 'A';
        return 'node#34_sal#$letter$salonNumber';
      }
      return 'node#34_sal#A200'; // Nodo por defecto piso 2
    }
    
    return 'node_32'; // Fallback
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
