import '../repositories/home_repository.dart';
import '../entities/location_entity.dart';

/// Use case para actualizar ubicación del usuario
class UpdateLocationUseCase {
  final HomeRepository _repository;

  UpdateLocationUseCase(this._repository);

  Future<void> call({
    required String userId,
    required LocationEntity location,
    required String campusStatus,
  }) async {
    return await _repository.updateUserLocation(
      userId: userId,
      location: location,
      campusStatus: campusStatus,
    );
  }
}

