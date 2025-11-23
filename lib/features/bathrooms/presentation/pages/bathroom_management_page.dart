import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../../../core/widgets/empty_states/index.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/index.dart';
import '../../data/models/bathroom_model.dart';
import '../widgets/index.dart';

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
    _updateBathroomStatusUseCase = sl<UpdateBathroomStatusUseCase>();
    _getBathroomsGroupedByFloorUseCase = sl<GetBathroomsGroupedByFloorUseCase>();
    _getUserNameUseCase = sl<GetUserNameUseCase>();
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
      builder: (context) => BathroomStatusDialog(
        bathroom: bathroom,
        onStatusSelected: (newStatus) {
          _updateBathroomStatus(bathroom, newStatus);
        },
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
            return EmptyState(
              icon: Icons.error_outline,
              message: 'Error al cargar datos',
              secondaryMessage: snapshot.error.toString(),
              iconColor: AppStyles.errorColor,
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.wc,
              message: 'No hay baños registrados',
              iconColor: AppStyles.greyMedium,
            );
          }

          final bathroomsByFloor = snapshot.data!;
          final floors = bathroomsByFloor.keys.toList()..sort((a, b) => a.compareTo(b));

          // Convertir entidades a modelos para la UI
          final bathroomsByFloorAsModels = bathroomsByFloor.map(
            (key, value) => MapEntry(
              key,
              value.map((entity) => BathroomModel.fromEntity(entity)).toList(),
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
                  padding: EdgeInsets.only(
                    bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
                  ),
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

