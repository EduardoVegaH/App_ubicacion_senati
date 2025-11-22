import 'dart:async';
import '../models/bathroom_model.dart';
import '../../domain/entities/bathroom_entity.dart';

/// Fuente de datos remota para baños (actualmente usa datos estáticos)
class BathroomRemoteDataSource {
  // Datos estáticos para MVP - 10 pisos (del 1 al 10)
  final List<BathroomModel> _staticBathrooms = [
    // Piso 10
    BathroomModel(
      id: '1',
      nombre: 'Baño Hombres 10mo Piso',
      piso: 10,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '2',
      nombre: 'Baño Mujeres 10mo Piso',
      piso: 10,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 9
    BathroomModel(
      id: '3',
      nombre: 'Baño Hombres 9no Piso',
      piso: 9,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '4',
      nombre: 'Baño Mujeres 9no Piso',
      piso: 9,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 8
    BathroomModel(
      id: '5',
      nombre: 'Baño Hombres 8vo Piso',
      piso: 8,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '6',
      nombre: 'Baño Mujeres 8vo Piso',
      piso: 8,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 7
    BathroomModel(
      id: '7',
      nombre: 'Baño Hombres 7mo Piso',
      piso: 7,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '8',
      nombre: 'Baño Mujeres 7mo Piso',
      piso: 7,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 6
    BathroomModel(
      id: '9',
      nombre: 'Baño Hombres 6to Piso',
      piso: 6,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '10',
      nombre: 'Baño Mujeres 6to Piso',
      piso: 6,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 5 - En limpieza
    BathroomModel(
      id: '11',
      nombre: 'Baño Hombres 5to Piso',
      piso: 5,
      estado: BathroomStatus.en_limpieza,
      tipo: 'hombres',
      usuarioLimpiezaNombre: 'Juan Pérez',
      inicioLimpieza: DateTime.now().subtract(const Duration(minutes: 15)),
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '12',
      nombre: 'Baño Mujeres 5to Piso',
      piso: 5,
      estado: BathroomStatus.en_limpieza,
      tipo: 'mujeres',
      usuarioLimpiezaNombre: 'María García',
      inicioLimpieza: DateTime.now().subtract(const Duration(minutes: 10)),
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 4
    BathroomModel(
      id: '13',
      nombre: 'Baño Hombres 4to Piso',
      piso: 4,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '14',
      nombre: 'Baño Mujeres 4to Piso',
      piso: 4,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 3 - En limpieza
    BathroomModel(
      id: '15',
      nombre: 'Baño Hombres 3er Piso',
      piso: 3,
      estado: BathroomStatus.en_limpieza,
      tipo: 'hombres',
      usuarioLimpiezaNombre: 'Carlos López',
      inicioLimpieza: DateTime.now().subtract(const Duration(minutes: 5)),
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '16',
      nombre: 'Baño Mujeres 3er Piso',
      piso: 3,
      estado: BathroomStatus.en_limpieza,
      tipo: 'mujeres',
      usuarioLimpiezaNombre: 'Ana Martínez',
      inicioLimpieza: DateTime.now().subtract(const Duration(minutes: 8)),
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 2
    BathroomModel(
      id: '17',
      nombre: 'Baño Hombres 2do Piso',
      piso: 2,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '18',
      nombre: 'Baño Mujeres 2do Piso',
      piso: 2,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
    // Piso 1
    BathroomModel(
      id: '19',
      nombre: 'Baño Hombres 1er Piso',
      piso: 1,
      estado: BathroomStatus.operativo,
      tipo: 'hombres',
      ultimaActualizacion: DateTime.now(),
    ),
    BathroomModel(
      id: '20',
      nombre: 'Baño Mujeres 1er Piso',
      piso: 1,
      estado: BathroomStatus.operativo,
      tipo: 'mujeres',
      ultimaActualizacion: DateTime.now(),
    ),
  ];

  Stream<List<BathroomModel>> getBathroomsStream() {
    return Stream.value(_staticBathrooms);
  }

  Stream<List<BathroomModel>> getBathroomsByFloor(int piso) {
    return Stream.value(
      _staticBathrooms.where((b) => b.piso == piso).toList(),
    );
  }

  Future<BathroomModel?> getBathroom(String id) async {
    try {
      return _staticBathrooms.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBathroomStatus(
    String bathroomId,
    BathroomStatus nuevoEstado, {
    String? usuarioLimpiezaNombre,
  }) async {
    final index = _staticBathrooms.indexWhere((b) => b.id == bathroomId);
    if (index == -1) {
      throw Exception('Baño no encontrado');
    }

    final bathroom = _staticBathrooms[index];
    final now = DateTime.now();

    _staticBathrooms[index] = bathroom.copyWith(
      estado: nuevoEstado,
      ultimaActualizacion: now,
      usuarioLimpiezaNombre: nuevoEstado == BathroomStatus.en_limpieza
          ? (usuarioLimpiezaNombre ?? 'Personal de Limpieza')
          : bathroom.usuarioLimpiezaNombre,
      inicioLimpieza: nuevoEstado == BathroomStatus.en_limpieza
          ? now
          : bathroom.inicioLimpieza,
      finLimpieza: (nuevoEstado != BathroomStatus.en_limpieza &&
              bathroom.estado == BathroomStatus.en_limpieza)
          ? now
          : bathroom.finLimpieza,
    );

    await Future.delayed(const Duration(milliseconds: 100));
  }

  Stream<Map<int, List<BathroomModel>>> getBathroomsGroupedByFloor() {
    return Stream.value(() {
      final grouped = <int, List<BathroomModel>>{};
      for (var bathroom in _staticBathrooms) {
        if (!grouped.containsKey(bathroom.piso)) {
          grouped[bathroom.piso] = [];
        }
        grouped[bathroom.piso]!.add(bathroom);
      }
      return grouped;
    }());
  }
}

