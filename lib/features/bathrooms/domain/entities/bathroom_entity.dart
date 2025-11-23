/// Entidad de baño (sin dependencias externas)
class BathroomEntity {
  final String id;
  final String nombre;
  final int piso;
  final BathroomStatus estado;
  final String? tipo;
  final String? usuarioLimpiezaId;
  final String? usuarioLimpiezaNombre;
  final DateTime? inicioLimpieza;
  final DateTime? finLimpieza;
  final DateTime? ultimaActualizacion;

  BathroomEntity({
    required this.id,
    required this.nombre,
    required this.piso,
    required this.estado,
    this.tipo,
    this.usuarioLimpiezaId,
    this.usuarioLimpiezaNombre,
    this.inicioLimpieza,
    this.finLimpieza,
    this.ultimaActualizacion,
  });
}

/// Enum para el estado del baño
enum BathroomStatus {
  operativo,
  en_limpieza,
  inoperativo,
}


