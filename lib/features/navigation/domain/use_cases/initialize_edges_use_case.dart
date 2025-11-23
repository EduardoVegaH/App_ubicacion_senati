import '../../data/services/graph_initializer.dart';

/// Caso de uso para inicializar los edges de un piso
/// 
/// Usa GraphInitializer para generar edges bidireccionales desde la configuración manual
/// y guardarlos en Firestore
class InitializeEdgesUseCase {
  final GraphInitializer graphInitializer;

  InitializeEdgesUseCase(this.graphInitializer);

  /// Inicializa los edges para un piso específico
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna el número de edges creados
  Future<int> call(int floor) {
    return graphInitializer.initializeEdgesForFloor(floor);
  }

  /// Inicializa los edges para todos los pisos configurados
  /// 
  /// Retorna un mapa con el número de edges creados por piso
  Future<Map<int, int>> callAll() {
    return graphInitializer.initializeAllEdges();
  }
}

