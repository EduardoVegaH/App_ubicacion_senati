import 'dart:async';
import '../entities/bathroom_entity.dart';
import '../repositories/bathroom_repository.dart';

/// Caso de uso para obtener baños por piso
class GetBathroomsByFloorUseCase {
  final BathroomRepository _repository;
  
  GetBathroomsByFloorUseCase(this._repository);
  
  Stream<List<BathroomEntity>> call(int piso) {
    return _repository.getBathroomsByFloor(piso);
  }
}

