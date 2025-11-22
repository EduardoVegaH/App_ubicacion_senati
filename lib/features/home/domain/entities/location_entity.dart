/// Entidad de ubicación
class LocationEntity {
  final double latitude;
  final double longitude;

  LocationEntity({
    required this.latitude,
    required this.longitude,
  });
}

/// Entidad de polígono del campus
class CampusPolygonEntity {
  final List<LocationEntity> points;

  CampusPolygonEntity({required this.points});
}

