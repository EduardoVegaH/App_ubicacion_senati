import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/location_entity.dart';
import '../data_sources/home_remote_data_source.dart';
import '../data_sources/location_data_source.dart';
import '../models/student_model.dart';

/// Implementación del repositorio de home
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final LocationDataSource _locationDataSource;

  HomeRepositoryImpl(
    this._remoteDataSource,
    this._locationDataSource,
  );

  @override
  Future<StudentEntity?> getStudentData() async {
    final data = await _remoteDataSource.getUserData();
    if (data == null) return null;

    // Convertir a modelo y luego a entidad
    final model = StudentModel.fromFirestore(data);
    return model.toEntity();
  }

  @override
  Future<void> updateUserLocation({
    required String userId,
    required LocationEntity location,
    required String campusStatus,
  }) async {
    await _remoteDataSource.updateUserLocation(
      userId: userId,
      latitude: location.latitude,
      longitude: location.longitude,
      campusStatus: campusStatus,
    );
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }
}

