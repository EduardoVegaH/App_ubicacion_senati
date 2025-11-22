import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../data/index.dart';
import '../../domain/index.dart';

/// Página de estado de baños (refactorizada)
class BathroomStatusPage extends StatefulWidget {
  const BathroomStatusPage({super.key});

  @override
  State<BathroomStatusPage> createState() => _BathroomStatusPageState();
}

class _BathroomStatusPageState extends State<BathroomStatusPage> {
  late final BathroomRemoteDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = BathroomRemoteDataSource();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBar(
        title: const Text('Estado de Baños'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
        elevation: 0,
      ),
      body: StreamBuilder<Map<int, List<BathroomModel>>>(
        stream: _dataSource.getBathroomsGroupedByFloor(),
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
                  Text(
                    'Error al cargar datos: ${snapshot.error}',
                    style: TextStyle(color: AppStyles.errorColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wc, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay baños registrados',
                      style: TextStyle(
                        color: AppStyles.textPrimary,
                        fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final bathroomsByFloor = snapshot.data!;
          final floors = bathroomsByFloor.keys.toList()..sort((a, b) => a.compareTo(b));

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 20 : 14)),
              itemCount: floors.length,
              itemBuilder: (context, index) {
                final piso = floors[index];
                final bathrooms = bathroomsByFloor[piso]!;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
                  ),
                  child: _FloorCard(
                    piso: piso,
                    bathrooms: bathrooms,
                    isLargePhone: isLargePhone,
                    isTablet: isTablet,
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

class _FloorCard extends StatelessWidget {
  final int piso;
  final List<BathroomModel> bathrooms;
  final bool isLargePhone;
  final bool isTablet;

  const _FloorCard({
    required this.piso,
    required this.bathrooms,
    required this.isLargePhone,
    required this.isTablet,
  });

  BathroomStatus _getFloorStatus() {
    if (bathrooms.every((b) => b.estado == BathroomStatus.operativo)) {
      return BathroomStatus.operativo;
    }
    if (bathrooms.any((b) => b.estado == BathroomStatus.en_limpieza)) {
      return BathroomStatus.en_limpieza;
    }
    return BathroomStatus.inoperativo;
  }

  @override
  Widget build(BuildContext context) {
    final floorStatus = _getFloorStatus();

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isLargePhone ? 18 : (isTablet ? 20 : 16),
            vertical: isLargePhone ? 8 : (isTablet ? 10 : 6),
          ),
          childrenPadding: EdgeInsets.only(
            bottom: isLargePhone ? 8 : (isTablet ? 10 : 6),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: isLargePhone ? 48 : (isTablet ? 52 : 44),
            height: isLargePhone ? 48 : (isTablet ? 52 : 44),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.wc,
                size: isLargePhone ? 24 : (isTablet ? 26 : 22),
                color: AppStyles.primaryColor,
              ),
            ),
          ),
          title: Text(
            'Piso $piso',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
              color: const Color(0xFF2C2C2C),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(floorStatus.icon, size: isLargePhone ? 18 : (isTablet ? 20 : 16), color: floorStatus.color),
                const SizedBox(width: 6),
                Text(
                  floorStatus.label,
                  style: TextStyle(
                    color: floorStatus.color,
                    fontWeight: FontWeight.w500,
                    fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                  ),
                ),
              ],
            ),
          ),
          children: bathrooms.map((bathroom) => _BathroomTile(
            bathroom: bathroom,
            isLargePhone: isLargePhone,
            isTablet: isTablet,
          )).toList(),
        ),
      ),
    );
  }
}

class _BathroomTile extends StatelessWidget {
  final BathroomModel bathroom;
  final bool isLargePhone;
  final bool isTablet;

  const _BathroomTile({
    required this.bathroom,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 18 : (isTablet ? 20 : 16),
        vertical: 4,
      ),
      padding: EdgeInsets.all(isLargePhone ? 14 : (isTablet ? 16 : 12)),
      decoration: BoxDecoration(
        color: bathroom.estado.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bathroom.estado.color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(bathroom.estado.icon, size: isLargePhone ? 20 : (isTablet ? 22 : 18), color: bathroom.estado.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bathroom.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bathroom.estado.label,
                  style: TextStyle(
                    color: bathroom.estado.color,
                    fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (bathroom.estado == BathroomStatus.en_limpieza && bathroom.usuarioLimpiezaNombre != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: isLargePhone ? 14 : (isTablet ? 15 : 13), color: AppStyles.textSecondary),
                      const SizedBox(width: 4),
                      Text(bathroom.usuarioLimpiezaNombre!, style: TextStyle(color: AppStyles.textSecondary, fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11))),
                      if (bathroom.inicioLimpieza != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: isLargePhone ? 14 : (isTablet ? 15 : 13), color: AppStyles.textSecondary),
                        const SizedBox(width: 4),
                        Text(dateFormat.format(bathroom.inicioLimpieza!), style: TextStyle(color: AppStyles.textSecondary, fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11))),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

