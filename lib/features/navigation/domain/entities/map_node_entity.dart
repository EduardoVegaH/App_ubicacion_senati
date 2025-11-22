/// Entidad de nodo del mapa (sin dependencias externas)
class MapNodeEntity {
  final String id;
  final double x;
  final double y;
  final int piso;
  final String? tipo;
  final String? salonId;

  const MapNodeEntity({
    required this.id,
    required this.x,
    required this.y,
    required this.piso,
    this.tipo,
    this.salonId,
  });
}

