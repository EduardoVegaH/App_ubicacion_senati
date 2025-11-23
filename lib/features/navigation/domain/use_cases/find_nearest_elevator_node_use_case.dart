import '../entities/map_node_entity.dart';
import '../repositories/navigation_repository.dart';

/// Use case para encontrar el nodo más cercano a los ascensores
class FindNearestElevatorNodeUseCase {
  final NavigationRepository _repository;

  FindNearestElevatorNodeUseCase(this._repository);

  /// Encontrar el nodo más cercano a los ascensores en un piso
  Future<MapNodeEntity?> call(int piso) async {
    return await _repository.findNearestElevatorNode(piso);
  }
}

