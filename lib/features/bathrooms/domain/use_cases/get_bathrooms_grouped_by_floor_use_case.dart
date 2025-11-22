import 'dart:async';
import '../entities/bathroom_entity.dart';
import '../repositories/bathroom_repository.dart';

/// Caso de uso para obtener baños agrupados por piso
class GetBathroomsGroupedByFloorUseCase {
  final BathroomRepository _repository;
  
  GetBathroomsGroupedByFloorUseCase(this._repository);
  
  Stream<Map<int, List<BathroomEntity>>> call() {
    return _repository.getBathroomsGroupedByFloor();
  }
}

