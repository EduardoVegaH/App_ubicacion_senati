import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../domain/index.dart';
import '../../data/data_sources/svg_map_data_source.dart';

/// Página de administración del grafo de navegación
/// 
/// Permite inicializar los grafos de los pisos desde los archivos SVG
class GraphAdminPage extends StatefulWidget {
  const GraphAdminPage({super.key});

  @override
  State<GraphAdminPage> createState() => _GraphAdminPageState();
}

class _GraphAdminPageState extends State<GraphAdminPage> {
  late final InitializeFloorGraphUseCase _initializeFloorGraphUseCase;
  late final InitializeEdgesUseCase _initializeEdgesUseCase;
  late final SvgMapDataSource _svgMapDataSource;
  bool _initializingPiso1 = false;
  bool _initializingPiso2 = false;
  bool _initializingEdgesPiso1 = false;
  bool _initializingEdgesPiso2 = false;

  @override
  void initState() {
    super.initState();
    _initializeFloorGraphUseCase = sl<InitializeFloorGraphUseCase>();
    _initializeEdgesUseCase = sl<InitializeEdgesUseCase>();
    _svgMapDataSource = SvgMapDataSource();
  }

  Future<void> _initializeFloor(int floor) async {
    if (floor == 1 && _initializingPiso1) return;
    if (floor == 2 && _initializingPiso2) return;

    setState(() {
      if (floor == 1) {
        _initializingPiso1 = true;
      } else {
        _initializingPiso2 = true;
      }
    });

    try {
      // Determinar la ruta del SVG según el piso
      final svgAssetPath = floor == 1
          ? 'assets/mapas/MAP_PISO_1.svg'
          : 'assets/mapas/MAP_PISO_2.svg';

      // Parsear el SVG y construir el MapFloor
      final mapFloor = await _svgMapDataSource.buildFloorFromSvg(
        floor: floor,
        assetPath: svgAssetPath,
      );

      // Guardar en Firestore usando el use case
      await _initializeFloorGraphUseCase.call(mapFloor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Piso $floor inicializado correctamente con ${mapFloor.nodes.length} nodos'),
            backgroundColor: AppStyles.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar piso $floor: $e'),
            backgroundColor: AppStyles.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (floor == 1) {
            _initializingPiso1 = false;
          } else {
            _initializingPiso2 = false;
          }
        });
      }
    }
  }

  Future<void> _initializeEdges(int floor) async {
    if (floor == 1 && _initializingEdgesPiso1) return;
    if (floor == 2 && _initializingEdgesPiso2) return;

    setState(() {
      if (floor == 1) {
        _initializingEdgesPiso1 = true;
      } else {
        _initializingEdgesPiso2 = true;
      }
    });

    try {
      // Inicializar edges usando el use case
      final edgesCount = await _initializeEdgesUseCase.call(floor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edges del piso $floor inicializados correctamente: $edgesCount edges creados'),
            backgroundColor: AppStyles.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar edges del piso $floor: $e'),
            backgroundColor: AppStyles.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (floor == 1) {
            _initializingEdgesPiso1 = false;
          } else {
            _initializingEdgesPiso2 = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: const AppBarWithTitle(
        title: 'Administración de Grafo',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: Padding(
        padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Inicializar Grafos de Navegación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Parsea los archivos SVG y guarda los nodos en Firestore',
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Paso 1: Inicializar Nodos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carga los nodos desde los archivos SVG',
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializingPiso1
                  ? null
                  : () => _initializeFloor(1),
              icon: _initializingPiso1
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.map),
              label: Text(_initializingPiso1 ? 'Inicializando...' : 'Inicializar piso 1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: AppStyles.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializingPiso2
                  ? null
                  : () => _initializeFloor(2),
              icon: _initializingPiso2
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.map),
              label: Text(_initializingPiso2 ? 'Inicializando...' : 'Inicializar piso 2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: AppStyles.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Paso 2: Inicializar Edges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera las conexiones entre nodos basadas en configuración manual',
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializingEdgesPiso1
                  ? null
                  : () => _initializeEdges(1),
              icon: _initializingEdgesPiso1
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.route),
              label: Text(_initializingEdgesPiso1 ? 'Inicializando...' : 'Inicializar edges piso 1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: AppStyles.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializingEdgesPiso2
                  ? null
                  : () => _initializeEdges(2),
              icon: _initializingEdgesPiso2
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.route),
              label: Text(_initializingEdgesPiso2 ? 'Inicializando...' : 'Inicializar edges piso 2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: AppStyles.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

