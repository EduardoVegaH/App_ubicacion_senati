import 'dart:async';
import '../entities/bathroom_entity.dart';

/// Interfaz del repositorio de baños
abstract class BathroomRepository {
  Stream<List<BathroomEntity>> getBathroomsStream();
  Stream<List<BathroomEntity>> getBathroomsByFloor(int piso);
  Future<BathroomEntity?> getBathroom(String id);
  Future<void> updateBathroomStatus(
    String bathroomId,
    BathroomStatus nuevoEstado, {
    String? usuarioLimpiezaNombre,
  });
  Stream<Map<int, List<BathroomEntity>>> getBathroomsGroupedByFloor();
}

