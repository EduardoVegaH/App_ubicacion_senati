import 'package:flutter/material.dart';
import '../../../home/domain/entities/student_entity.dart';
import '../../../home/domain/entities/course_status_entity.dart';
import '../../../home/domain/entities/attendance_entity.dart';
import '../../../home/domain/use_cases/get_course_status_use_case.dart';
import '../../../navigation/presentation/index.dart';
import '../../../navigation/domain/repositories/navigation_repository.dart';
import '../../../navigation/domain/use_cases/find_nearest_elevator_node.dart';
import '../../../../core/di/injection_container.dart' as sl;
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
                      onPressed: () async {
                        // Extraer información del salón desde locationDetail (más confiable)
                        // Formato esperado: "Torre B, Piso 2, Salón 200" o "Comedor, Piso 1"
                        final piso = _extractPiso(widget.course.locationDetail);
                        final torre = _extractTorre(widget.course.locationDetail);
                        final salonNumber = _extractSalonNumber(widget.course.locationDetail);
                        
                        // Construir el salonKey para el mapeo (ej: "B200" o "Comedor")
                        String salonKey = '';
                        
                        // Primero verificar si es un lugar especial (Comedor, Biblioteca, etc.)
                        final locationDetailLower = widget.course.locationDetail.toLowerCase();
                        if (locationDetailLower.contains('comedor') || 
                            locationDetailLower.contains('biblioteca') || 
                            locationDetailLower.contains('biblio') ||
                            locationDetailLower.contains('oficina')) {
                          // Es un lugar especial, usar el locationDetail completo
                          salonKey = widget.course.locationDetail;
                          print('🔍 Lugar especial detectado: $salonKey');
                        } else if (torre != null && salonNumber != null) {
                          salonKey = '$torre$salonNumber';
                          print('🔍 Salón extraído: Torre=$torre, Número=$salonNumber, Clave=$salonKey');
                        } else if (salonNumber != null) {
                          // Si solo hay número sin torre (piso 1)
                          salonKey = salonNumber;
                          print('🔍 Salón extraído (piso 1): Número=$salonNumber, Clave=$salonKey');
                        } else {
                          // Si no hay número, puede ser un lugar especial
                          salonKey = widget.course.locationDetail;
                          print('🔍 Lugar especial detectado (fallback): $salonKey');
                        }
                        
                        // Mapear salón a nodo de destino dinámicamente desde Firestore
                        // Esto permite que el sistema se adapte automáticamente si cambian los números de los salones
                        final toNodeId = await _findNodeIdForSalon(salonKey, piso);
                        
                        // Nodo de origen: buscar el nodo más cercano a los ascensores
                        // Para piso 2, esto será el punto de partida más lógico
                        String fromNodeId;
                        if (piso == 1) {
                          fromNodeId = 'node_puerta_main01';
                        } else {
                          // Para piso 2, buscar el nodo más cercano a los ascensores
                          try {
                            final findNearestElevatorNode = sl.sl<FindNearestElevatorNodeUseCase>();
                            final nearestNode = await findNearestElevatorNode.call(piso);
                            fromNodeId = nearestNode?.id ?? 'node#37'; // Fallback si no encuentra
                            print('🚪 Nodo de partida (cercano a ascensores): $fromNodeId');
                          } catch (e) {
                            print('⚠️ Error buscando nodo cercano a ascensores: $e');
                            fromNodeId = 'node#37'; // Fallback
                          }
                        }
                        
                        print('🧭 Navegando: piso $piso, desde $fromNodeId hasta $toNodeId (salón: $salonKey)');
                        print('⚠️ Si falla, verifica que los nodos existan en Firestore: /mapas/piso_$piso/nodes/');
                        
                        if (!context.mounted) return;
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

  String? _extractTorre(String locationDetail) {
    // Formato: "Torre B, Piso 2, Salón 200"
    final torreMatch = RegExp(r'Torre\s+([A-C])').firstMatch(locationDetail);
    if (torreMatch != null) {
      return torreMatch.group(1);
    }
    return null;
  }

  String? _extractSalonNumber(String locationDetail) {
    // Formato: "Torre B, Piso 2, Salón 200"
    final salonMatch = RegExp(r'Salón\s+(\d+)').firstMatch(locationDetail);
    if (salonMatch != null) {
      return salonMatch.group(1);
    }
    return null;
  }

  /// Encuentra el ID del nodo correspondiente a un salón dinámicamente
  /// 
  /// Busca en Firestore los nodos que coincidan con el patrón del salón
  /// Esto permite que el sistema se adapte automáticamente si cambian los números de los salones
  /// 
  /// [salonKey] Clave del salón en formato "B200", "A201", o "Comedor, Piso 1" para lugares especiales
  /// [piso] Número de piso
  /// 
  /// Retorna el ID del nodo encontrado o lanza excepción si no se encuentra
  Future<String> _findNodeIdForSalon(String salonKey, int piso) async {
    if (piso == 1) {
      // Para piso 1, buscar dinámicamente en Firestore
      try {
        final repository = sl.sl<NavigationRepository>();
        final nodes = await repository.getNodesForFloor(piso);
        
        // Primero verificar si es un lugar especial (antes de buscar números)
        final locationText = salonKey.toLowerCase();
        final isSpecialPlace = locationText.contains('comedor') || 
            locationText.contains('biblioteca') || 
            locationText.contains('biblio') ||
            locationText.contains('oficina');
        
        if (isSpecialPlace) {
          // Es un lugar especial, buscar directamente
          print('🔍 Detectado lugar especial: $salonKey, buscando directamente...');
          
          // Buscar nodos especiales del piso 1
          if (locationText.contains('comedor')) {
            print('🔍 Buscando nodo de comedor en ${nodes.length} nodos disponibles...');
            
            // Buscar nodos que contengan "comedor" en su ID (case insensitive)
            final comedorNodes = nodes.where((node) => 
              node.id.toLowerCase().contains('comedor')
            ).toList();
            
            print('   Nodos con "comedor" en ID: ${comedorNodes.length}');
            if (comedorNodes.isNotEmpty) {
              for (var node in comedorNodes) {
                print('     - ${node.id} (${node.x.toStringAsFixed(1)}, ${node.y.toStringAsFixed(1)})');
              }
            }
            
            // También buscar por ID exacto
            final exactNode = nodes.where((n) => n.id == 'node_puerta_comedor').toList();
            print('   Nodos con ID exacto "node_puerta_comedor": ${exactNode.length}');
            
            if (comedorNodes.isNotEmpty) {
              final comedorNode = comedorNodes.first;
              print('✅ Nodo encontrado para Comedor (piso 1): ${comedorNode.id} (${comedorNode.x.toStringAsFixed(1)}, ${comedorNode.y.toStringAsFixed(1)})');
              return comedorNode.id;
            } else if (exactNode.isNotEmpty) {
              print('✅ Nodo encontrado por ID exacto: node_puerta_comedor');
              return 'node_puerta_comedor';
            } else {
              print('❌ El nodo node_puerta_comedor NO existe en Firestore');
              print('   Total nodos disponibles: ${nodes.length}');
              print('   Primeros 20 IDs: ${nodes.take(20).map((n) => n.id).join(", ")}');
              print('   Buscando nodos con "puerta" en el ID...');
              final puertaNodes = nodes.where((n) => n.id.contains('puerta')).toList();
              print('   Nodos con "puerta": ${puertaNodes.map((n) => n.id).join(", ")}');
              
              throw Exception('El nodo del comedor (node_puerta_comedor) no existe en Firestore. '
                  'Por favor, re-inicializa los nodos del piso 1 desde la pantalla de administración.');
            }
          } else if (locationText.contains('biblioteca') || locationText.contains('biblio')) {
            try {
              final biblioNode = nodes.firstWhere(
                (node) => node.id.contains('biblio'),
              );
              print('✅ Nodo encontrado para Biblioteca (piso 1): ${biblioNode.id}');
              return biblioNode.id;
            } catch (e) {
              print('⚠️ No se encontró nodo de biblioteca, usando fallback');
              return 'node_puerta_biblio';
            }
          } else if (locationText.contains('oficina')) {
            try {
              final oficinaNode = nodes.firstWhere(
                (node) => node.id.contains('oficina'),
              );
              print('✅ Nodo encontrado para Oficina (piso 1): ${oficinaNode.id}');
              return oficinaNode.id;
            } catch (e) {
              print('⚠️ No se encontró nodo de oficina, usando fallback');
              return 'node_puerta_oficina01';
            }
          }
          
          // Si llegamos aquí, es un lugar especial pero no se encontró
          print('⚠️ Lugar especial detectado pero no se encontró el nodo: $salonKey');
          throw Exception('No se encontró el nodo para el lugar especial: $salonKey');
        } else {
          // No es un lugar especial, buscar por número de salón
          // Normalizar la clave para extraer el número del salón
          final normalized = salonKey.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
          final numberMatch = RegExp(r'(\d+)').firstMatch(normalized);
          
          if (numberMatch != null) {
            final salonNumber = numberMatch.group(1)!;
            
            // Buscar nodos que:
            // 1. Tengan el número del salón en su ID
            // 2. Tengan el número del salón en su refId
            // 3. Sean de tipo 'salon'
            final matchingNodes = nodes.where((node) {
              final idContains = node.id.contains(salonNumber);
              final refIdContains = node.refId?.contains(salonNumber) ?? false;
              final isSalon = node.type == 'salon';
              
              return (idContains || refIdContains) && isSalon;
            }).toList();
            
            if (matchingNodes.isNotEmpty) {
              final nodeId = matchingNodes.first.id;
              print('✅ Nodo encontrado dinámicamente para salón $salonKey (piso 1): $nodeId');
              return nodeId;
            } else {
              print('⚠️ No se encontró nodo de salón para $salonKey en piso 1');
              print('   Nodos disponibles: ${nodes.length}');
              print('   Nodos de tipo salon: ${nodes.where((n) => n.type == 'salon').map((n) => n.id).join(", ")}');
              // Fallback: usar nodo de entrada principal
              return 'node_puerta_main01';
            }
          } else {
            print('⚠️ No se pudo extraer número del salón ni identificar lugar especial: $salonKey');
            print('   Nodos disponibles: ${nodes.length}');
            print('   Ejemplos de IDs: ${nodes.take(10).map((n) => n.id).join(", ")}');
            // Fallback: usar nodo de entrada principal
            return 'node_puerta_main01';
          }
        }
      } catch (e) {
        print('❌ Error buscando nodo dinámicamente para salón $salonKey (piso 1): $e');
        rethrow;
      }
    } else if (piso == 2) {
      // Para piso 2, buscar dinámicamente en Firestore
      // Normalizar la clave: asegurar que esté en formato "A200", "B201", etc.
      final normalized = salonKey.toUpperCase().replaceAll(RegExp(r'[^A-C0-9]'), '');
      
      // Extraer letra de torre (A, B, C) y número del salón
      final letterMatch = RegExp(r'([A-C])').firstMatch(normalized);
      final numberMatch = RegExp(r'(\d+)').firstMatch(normalized);
      
      if (letterMatch != null && numberMatch != null) {
        final letter = letterMatch.group(1)!;
        final number = numberMatch.group(1)!;
        
        // Construir patrón de búsqueda: sal#A200, sal#B201, etc.
        final salonPattern = 'sal#$letter$number';
        
        try {
          final repository = sl.sl<NavigationRepository>();
          final nodes = await repository.getNodesForFloor(piso);
          
          // Buscar nodos que contengan el patrón en su ID
          final matchingNodes = nodes.where((node) => 
            node.id.contains(salonPattern)
          ).toList();
          
          if (matchingNodes.isNotEmpty) {
            final nodeId = matchingNodes.first.id;
            print('✅ Nodo encontrado dinámicamente para salón $salonKey (piso 2): $nodeId');
            return nodeId;
          } else {
            print('⚠️ No se encontró nodo para salón $salonKey (patrón: $salonPattern)');
            print('   Nodos disponibles: ${nodes.length}');
            print('   Ejemplos de IDs: ${nodes.take(10).map((n) => n.id).join(", ")}');
            // Fallback: usar un nodo genérico
            return 'node#34_sal#A200';
          }
        } catch (e) {
          print('❌ Error buscando nodo dinámicamente para salón $salonKey (piso 2): $e');
          return 'node#34_sal#A200'; // Fallback
        }
      } else {
        print('⚠️ No se pudo extraer torre y número del salón: $salonKey');
        return 'node#34_sal#A200'; // Fallback
      }
    }
    
    return 'node_puerta_main01'; // Fallback genérico
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
