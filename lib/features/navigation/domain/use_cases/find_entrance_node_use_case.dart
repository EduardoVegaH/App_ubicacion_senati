import '../entities/map_node_entity.dart';
import '../repositories/navigation_repository.dart';

/// Use case para encontrar el nodo de entrada
class FindEntranceNodeUseCase {
  final NavigationRepository _repository;

  FindEntranceNodeUseCase(this._repository);

  /// Encontrar el nodo de entrada de un piso
  Future<MapNodeEntity?> call(int piso) async {
    return await _repository.findEntranceNode(piso);
  }
}

