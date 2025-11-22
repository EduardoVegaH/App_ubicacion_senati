import '../entities/map_node_entity.dart';
import '../repositories/navigation_repository.dart';

/// Caso de uso para encontrar nodo por salón
class FindNodeBySalonUseCase {
  final NavigationRepository _repository;
  
  FindNodeBySalonUseCase(this._repository);
  
  Future<MapNodeEntity?> call({
    required int piso,
    required String salonId,
  }) async {
    return await _repository.findNodeBySalon(
      piso: piso,
      salonId: salonId,
    );
  }
}

