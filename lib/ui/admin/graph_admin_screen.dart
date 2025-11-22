import 'package:flutter/material.dart';
import '../../navigation_map/utils/graph_initializer.dart';

/// Pantalla de administración para inicializar el grafo de navegación
class GraphAdminScreen extends StatefulWidget {
  const GraphAdminScreen({super.key});

  @override
  State<GraphAdminScreen> createState() => _GraphAdminScreenState();
}

class _GraphAdminScreenState extends State<GraphAdminScreen> {
  final GraphInitializer _initializer = GraphInitializer();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  Future<void> _initializeGraph() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Inicializando grafo...';
      _isSuccess = false;
    });

    try {
      await _initializer.initializeAllFloors(
        svgPaths: {
          1: 'assets/mapas/map_ext.svg',
          2: 'assets/mapas/map_int_piso2 (1).svg',
        },
      );

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Grafo inicializado correctamente';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _initializeFloor(int piso) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Inicializando piso $piso...';
      _isSuccess = false;
    });

    try {
      final svgPath = piso == 1
          ? 'assets/mapas/map_ext.svg'
          : 'assets/mapas/map_int_piso2 (1).svg';

      await _initializer.initializeFloor(piso: piso, svgPath: svgPath);

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Piso $piso inicializado correctamente';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Grafo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inicialización del Grafo de Navegación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta herramienta parsea los SVG, extrae los nodos, genera conexiones automáticamente y guarda todo en Firestore.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_statusMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initializeGraph,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.map),
              label: Text(_isLoading ? 'Inicializando...' : 'Inicializar Todos los Pisos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _initializeFloor(1),
              icon: const Icon(Icons.layers),
              label: const Text('Inicializar Solo Piso 1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _initializeFloor(2),
              icon: const Icon(Icons.layers),
              label: const Text('Inicializar Solo Piso 2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

