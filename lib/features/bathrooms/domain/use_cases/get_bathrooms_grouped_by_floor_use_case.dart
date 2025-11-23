import '../repositories/bathroom_repository.dart';
import '../entities/bathroom_entity.dart';

/// Use case para obtener baños agrupados por piso
class GetBathroomsGroupedByFloorUseCase {
  final BathroomRepository _repository;

  GetBathroomsGroupedByFloorUseCase(this._repository);

  Stream<Map<int, List<BathroomEntity>>> call() {
    return _repository.getBathroomsGroupedByFloor();
  }
}
