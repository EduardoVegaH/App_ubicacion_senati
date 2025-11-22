import 'dart:async';
import '../entities/bathroom_entity.dart';
import '../repositories/bathroom_repository.dart';

/// Caso de uso para obtener todos los baños
class GetBathroomsUseCase {
  final BathroomRepository _repository;
  
  GetBathroomsUseCase(this._repository);
  
  Stream<List<BathroomEntity>> call() {
    return _repository.getBathroomsStream();
  }
}

