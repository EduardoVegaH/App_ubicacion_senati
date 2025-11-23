import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/app_bar_with_title/app_bar_with_title.dart';
import '../../../../core/widgets/empty_state/empty_state.dart';
import '../../data/index.dart';
import '../../domain/index.dart';
import '../widgets/floor_card.dart';

/// Página de gestión de baños (refactorizada)
class BathroomManagementPage extends StatefulWidget {
  const BathroomManagementPage({super.key});

  @override
  State<BathroomManagementPage> createState() => _BathroomManagementPageState();
}

class _BathroomManagementPageState extends State<BathroomManagementPage> {
  late final UpdateBathroomStatusUseCase _updateBathroomStatusUseCase;
  late final GetBathroomsGroupedByFloorUseCase _getBathroomsGroupedByFloorUseCase;
  late final GetUserNameUseCase _getUserNameUseCase;
  String? _userName;

  @override
  void initState() {
    super.initState();
    final dataSource = BathroomRemoteDataSource();
    final repository = BathroomRepositoryImpl(dataSource);
    _updateBathroomStatusUseCase = UpdateBathroomStatusUseCase(repository);
    _getBathroomsGroupedByFloorUseCase = GetBathroomsGroupedByFloorUseCase(repository);
    _getUserNameUseCase = GetUserNameUseCase();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userName = await _getUserNameUseCase.call();
    setState(() {
      _userName = userName;
    });
  }

  Future<void> _updateBathroomStatus(BathroomModel bathroom, BathroomStatus nuevoEstado) async {
    try {
      await _updateBathroomStatusUseCase.call(
        bathroomId: bathroom.id,
        nuevoEstado: nuevoEstado,
        usuarioLimpiezaNombre: _userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado de ${bathroom.nombre} actualizado a ${nuevoEstado.label}'),
            backgroundColor: AppStyles.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: AppStyles.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showStatusDialog(BathroomModel bathroom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar estado: ${bathroom.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              status: BathroomStatus.operativo,
              currentStatus: bathroom.estado,
              onTap: () {
                Navigator.pop(context);
                _updateBathroomStatus(bathroom, BathroomStatus.operativo);
              },
            ),
            const SizedBox(height: 8),
            _StatusOption(
              status: BathroomStatus.en_limpieza,
              currentStatus: bathroom.estado,
              onTap: () {
                Navigator.pop(context);
                _updateBathroomStatus(bathroom, BathroomStatus.en_limpieza);
              },
            ),
            const SizedBox(height: 8),
            _StatusOption(
              status: BathroomStatus.inoperativo,
              currentStatus: bathroom.estado,
              onTap: () {
                Navigator.pop(context);
                _updateBathroomStatus(bathroom, BathroomStatus.inoperativo);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: const AppBarWithTitle(
        title: 'Gestión de Baños',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: StreamBuilder<Map<int, List<BathroomEntity>>>(
        stream: _getBathroomsGroupedByFloorUseCase.call(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppStyles.errorColor),
                  const SizedBox(height: 16),
                  Text('Error al cargar datos: ${snapshot.error}', style: TextStyle(color: AppStyles.errorColor), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => setState(() {}), child: const Text('Reintentar')),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wc, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No hay baños registrados', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final bathroomsByFloor = snapshot.data!;
          final floors = bathroomsByFloor.keys.toList()..sort((a, b) => a.compareTo(b));

          // Convertir entidades a modelos para la UI
          final bathroomsByFloorAsModels = bathroomsByFloor.map(
            (key, value) => MapEntry(
              key,
              value.map((entity) => BathroomModel(
                id: entity.id,
                nombre: entity.nombre,
                piso: entity.piso,
                estado: entity.estado,
                tipo: entity.tipo,
                usuarioLimpiezaId: entity.usuarioLimpiezaId,
                usuarioLimpiezaNombre: entity.usuarioLimpiezaNombre,
                inicioLimpieza: entity.inicioLimpieza,
                finLimpieza: entity.finLimpieza,
                ultimaActualizacion: entity.ultimaActualizacion,
              )).toList(),
            ),
          );

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
              itemCount: floors.length,
              itemBuilder: (context, index) {
                final piso = floors[index];
                final bathrooms = bathroomsByFloorAsModels[piso]!;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLargePhone ? 12 : (isTablet ? 14 : 10)),
                  child: FloorCard(
                    piso: piso,
                    bathrooms: bathrooms,
                    onBathroomTap: _showStatusDialog,
                    showEditIcon: true,
                    showBathroomCount: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final BathroomStatus status;
  final BathroomStatus currentStatus;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.currentStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = status == currentStatus;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? status.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? status.color : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(status.icon, size: 24, color: status.color),
            const SizedBox(width: 12),
            Expanded(child: Text(status.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: status.color, fontSize: 16))),
            if (isSelected) Icon(Icons.check_circle, color: status.color),
          ],
        ),
      ),
    );
  }
}

