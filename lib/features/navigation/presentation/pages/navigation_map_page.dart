import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../domain/index.dart';
import '../../domain/use_cases/get_route_to_room.dart';
import '../widgets/map_canvas.dart';

/// Página de navegación que muestra el mapa con la ruta calculada
class NavigationMapPage extends StatefulWidget {
  final int floor;
  final String fromNodeId;
  final String toNodeId;

  const NavigationMapPage({
    super.key,
    required this.floor,
    required this.fromNodeId,
    required this.toNodeId,
  });

  @override
  State<NavigationMapPage> createState() => _NavigationMapPageState();
}

class _NavigationMapPageState extends State<NavigationMapPage> {
  late final GetRouteToRoomUseCase _getRouteToRoomUseCase;
  List<MapNode>? _pathNodes;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🚀 NavigationMapPage initState: piso ${widget.floor}, desde ${widget.fromNodeId} hasta ${widget.toNodeId}');
    try {
      _getRouteToRoomUseCase = sl<GetRouteToRoomUseCase>();
      print('✅ GetRouteToRoomUseCase obtenido del service locator');
      _loadRoute();
    } catch (e, stackTrace) {
      print('❌ Error obteniendo GetRouteToRoomUseCase: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inicializando: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Calculando ruta: piso ${widget.floor}, desde ${widget.fromNodeId} hasta ${widget.toNodeId}');
      
      final path = await _getRouteToRoomUseCase.call(
        floor: widget.floor,
        fromNodeId: widget.fromNodeId,
        toNodeId: widget.toNodeId,
      );

      print('✅ Ruta encontrada: ${path.length} nodos');
      for (var node in path) {
        print('  - ${node.id} (${node.x}, ${node.y})');
      }

      if (mounted) {
        setState(() {
          _pathNodes = path;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error calculando ruta: $e');
      print('Stack trace: $stackTrace');
      
      // Mejorar el mensaje de error para que sea más útil
      String errorMessage = e.toString();
      if (e.toString().contains('no encontrado')) {
        errorMessage = '${e.toString()}\n\n'
            '💡 Verifica que:\n'
            '1. Los nodos estén inicializados en Firestore\n'
            '2. Los IDs de nodos sean correctos\n'
            '3. El piso sea el correcto (${widget.floor})';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _loading = false;
        });
      }
    }
  }

  String _getSvgAssetPath(int floor) {
    switch (floor) {
      case 1:
        return 'assets/mapas/MAP_PISO_1.svg';
      case 2:
        return 'assets/mapas/MAP_PISO_2.svg';
      default:
        return 'assets/mapas/MAP_PISO_1.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 NavigationMapPage build: loading=$_loading, error=${_errorMessage != null}, pathNodes=${_pathNodes?.length ?? 0}');
    
    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBarWithTitle(
        title: 'Navegación Piso ${widget.floor}',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppStyles.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al calcular la ruta',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppStyles.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRoute,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pathNodes != null && _pathNodes!.isNotEmpty
                  ? MapCanvas(
                      floor: widget.floor,
                      svgAssetPath: _getSvgAssetPath(widget.floor),
                      pathNodes: _pathNodes!,
                    )
                  : const Center(
                      child: Text('No se encontró una ruta'),
                    ),
    );
  }
}

