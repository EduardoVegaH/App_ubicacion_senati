import '../entities/bathroom_entity.dart';
import '../repositories/bathroom_repository.dart';

/// Caso de uso para actualizar el estado de un baño
class UpdateBathroomStatusUseCase {
  final BathroomRepository _repository;
  
  UpdateBathroomStatusUseCase(this._repository);
  
  Future<void> call({
    required String bathroomId,
    required BathroomStatus nuevoEstado,
    String? usuarioLimpiezaNombre,
  }) async {
    return await _repository.updateBathroomStatus(
      bathroomId,
      nuevoEstado,
      usuarioLimpiezaNombre: usuarioLimpiezaNombre,
    );
  }
}

