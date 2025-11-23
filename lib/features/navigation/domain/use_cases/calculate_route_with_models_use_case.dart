import '../../data/models/edge_model.dart';
import '../repositories/navigation_repository.dart';

/// Use case para calcular ruta y retornar modelos (para uso en UI)
/// 
/// Nota: Este use case retorna modelos en lugar de entidades para compatibilidad
/// con el código existente que usa EdgeModel directamente en la UI.
/// Idealmente la UI debería usar solo entidades, pero por compatibilidad
/// con el código existente que usa EdgeModel directamente, este use case
/// maneja la conversión de entidades a modelos.
/// 
/// TODO: Refactorizar para que la UI use entidades directamente.
class CalculateRouteWithModelsUseCase {
  final NavigationRepository _repository;

  CalculateRouteWithModelsUseCase(this._repository);

  Future<List<EdgeModel>> call({
    required int piso,
    required String startNodeId,
    required String endNodeId,
  }) async {
    final pathEntities = await _repository.findPath(
      piso: piso,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );

    // Convertir entidades a modelos
    return pathEntities.map((e) {
      return EdgeModel(
        fromId: e.fromId,
        toId: e.toId,
        weight: e.weight,
        piso: e.piso,
        tipo: e.tipo,
        shape: e.shape,
      );
    }).toList();
  }
}

