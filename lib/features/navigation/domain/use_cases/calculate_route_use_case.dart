import '../entities/edge_entity.dart';
import '../repositories/navigation_repository.dart';

/// Caso de uso para calcular ruta
class CalculateRouteUseCase {
  final NavigationRepository _repository;
  
  CalculateRouteUseCase(this._repository);
  
  Future<List<EdgeEntity>> call({
    required int piso,
    required String startNodeId,
    required String endNodeId,
  }) async {
    return await _repository.findPath(
      piso: piso,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
  }
}

