import '../entities/map_floor.dart';
import '../repositories/navigation_repository.dart';

/// Caso de uso para inicializar el grafo de un piso
/// 
/// Guarda el grafo completo (nodos + edges) en persistencia
class InitializeFloorGraphUseCase {
  final NavigationRepository repository;

  InitializeFloorGraphUseCase(this.repository);

  /// Inicializa el grafo de un piso
  /// 
  /// [floor] El grafo completo del piso a guardar
  Future<void> call(MapFloor floor) {
    return repository.saveFloorGraph(floor);
  }
}

