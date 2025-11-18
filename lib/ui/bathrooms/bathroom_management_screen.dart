image.pngimport 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bathroom_model.dart';
import '../../services/bathroom_service.dart';
import 'package:intl/intl.dart';

class BathroomManagementScreen extends StatefulWidget {
  const BathroomManagementScreen({super.key});

  @override
  State<BathroomManagementScreen> createState() =>
      _BathroomManagementScreenState();
}

class _BathroomManagementScreenState extends State<BathroomManagementScreen> {
  final BathroomService _bathroomService = BathroomService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email ?? 'Usuario';
      });
    }
  }

  Future<void> _updateBathroomStatus(
    BathroomModel bathroom,
    BathroomStatus nuevoEstado,
  ) async {
    try {
      await _bathroomService.updateBathroomStatus(
        bathroom.id,
        nuevoEstado,
        usuarioLimpiezaNombre: _userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado de ${bathroom.nombre} actualizado a ${nuevoEstado.label}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestión de Baños'),
        backgroundColor: const Color(0xFF1B38E3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<Map<int, List<BathroomModel>>>(
        stream: _bathroomService.getBathroomsGroupedByFloor(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wc, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay baños registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final bathroomsByFloor = snapshot.data!;
          final floors = bathroomsByFloor.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
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
                  child: _ManagementFloorCard(
                    piso: piso,
                    bathrooms: bathrooms,
                    onBathroomTap: _showStatusDialog,
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

class _ManagementFloorCard extends StatelessWidget {
  final int piso;
  final List<BathroomModel> bathrooms;
  final Function(BathroomModel) onBathroomTap;
  final bool isLargePhone;
  final bool isTablet;

  const _ManagementFloorCard({
    required this.piso,
    required this.bathrooms,
    required this.onBathroomTap,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
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
            color: const Color(0xFF1B38E3).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.wc,
              size: isLargePhone ? 24 : (isTablet ? 26 : 22),
              color: const Color(0xFF1B38E3),
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
          child: Text(
            '${bathrooms.length} baño${bathrooms.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: const Color(0xFF757575),
              fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
            ),
          ),
        ),
          children: bathrooms
              .map((bathroom) => _ManagementBathroomTile(
                    bathroom: bathroom,
                    onTap: () => onBathroomTap(bathroom),
                    isLargePhone: isLargePhone,
                    isTablet: isTablet,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ManagementBathroomTile extends StatelessWidget {
  final BathroomModel bathroom;
  final VoidCallback onTap;
  final bool isLargePhone;
  final bool isTablet;

  const _ManagementBathroomTile({
    required this.bathroom,
    required this.onTap,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isLargePhone ? 18 : (isTablet ? 20 : 16),
          vertical: 4,
        ),
        padding: EdgeInsets.all(isLargePhone ? 14 : (isTablet ? 16 : 12)),
        decoration: BoxDecoration(
          color: bathroom.estado.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: bathroom.estado.color,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              bathroom.estado.icon,
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
              color: bathroom.estado.color,
            ),
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
                  if (bathroom.estado == BathroomStatus.en_limpieza &&
                      bathroom.usuarioLimpiezaNombre != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: isLargePhone ? 14 : (isTablet ? 15 : 13),
                          color: const Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bathroom.usuarioLimpiezaNombre!,
                          style: TextStyle(
                            color: const Color(0xFF757575),
                            fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                          ),
                        ),
                        if (bathroom.inicioLimpieza != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: isLargePhone ? 14 : (isTablet ? 15 : 13),
                            color: const Color(0xFF757575),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(bathroom.inicioLimpieza!),
                            style: TextStyle(
                              color: const Color(0xFF757575),
                              fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
              color: bathroom.estado.color,
            ),
          ],
        ),
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
          color: isSelected
              ? status.color.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? status.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              status.icon,
              size: 24,
              color: status.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: status.color,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: status.color,
              ),
          ],
        ),
      ),
    );
  }
}

