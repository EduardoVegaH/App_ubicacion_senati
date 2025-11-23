import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/app_bar_with_title/app_bar_with_title.dart';
import '../../../../core/widgets/empty_state/empty_state.dart';
import '../../data/index.dart';
import '../../domain/index.dart';
import '../widgets/floor_card.dart';

/// Página de estado de baños (refactorizada)
class BathroomStatusPage extends StatefulWidget {
  const BathroomStatusPage({super.key});

  @override
  State<BathroomStatusPage> createState() => _BathroomStatusPageState();
}

class _BathroomStatusPageState extends State<BathroomStatusPage> {
  late final GetBathroomsGroupedByFloorUseCase _getBathroomsGroupedByFloorUseCase;

  @override
  void initState() {
    super.initState();
    final dataSource = BathroomRemoteDataSource();
    final repository = BathroomRepositoryImpl(dataSource);
    _getBathroomsGroupedByFloorUseCase = GetBathroomsGroupedByFloorUseCase(repository);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: const AppBarWithTitle(
        title: 'Estado de Baños',
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
              message: 'Error al cargar datos: ${snapshot.error}',
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.wc,
              message: 'No hay baños registrados',
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
                  padding: EdgeInsets.only(
                    bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
                  ),
                  child: FloorCard(
                    piso: piso,
                    bathrooms: bathrooms,
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

