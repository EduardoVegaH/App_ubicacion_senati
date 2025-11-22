import 'dart:async';
import '../../domain/entities/bathroom_entity.dart';
import '../../domain/repositories/bathroom_repository.dart';
import '../data_sources/bathroom_remote_data_source.dart';

/// Implementación del repositorio de baños
class BathroomRepositoryImpl implements BathroomRepository {
  final BathroomRemoteDataSource _dataSource;
  
  BathroomRepositoryImpl(this._dataSource);
  
  @override
  Stream<List<BathroomEntity>> getBathroomsStream() {
    return _dataSource.getBathroomsStream().map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }
  
  @override
  Stream<List<BathroomEntity>> getBathroomsByFloor(int piso) {
    return _dataSource.getBathroomsByFloor(piso).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }
  
  @override
  Future<BathroomEntity?> getBathroom(String id) async {
    final model = await _dataSource.getBathroom(id);
    return model?.toEntity();
  }
  
  @override
  Future<void> updateBathroomStatus(
    String bathroomId,
    BathroomStatus nuevoEstado, {
    String? usuarioLimpiezaNombre,
  }) async {
    return await _dataSource.updateBathroomStatus(
      bathroomId,
      nuevoEstado,
      usuarioLimpiezaNombre: usuarioLimpiezaNombre,
    );
  }
  
  @override
  Stream<Map<int, List<BathroomEntity>>> getBathroomsGroupedByFloor() {
    return _dataSource.getBathroomsGroupedByFloor().map(
      (grouped) => grouped.map(
        (key, value) => MapEntry(
          key,
          value.map((m) => m.toEntity()).toList(),
        ),
      ),
    );
  }
}

