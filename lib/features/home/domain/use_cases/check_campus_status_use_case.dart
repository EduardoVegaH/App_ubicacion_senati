import '../entities/location_entity.dart';
import '../entities/course_status_entity.dart';

/// Use case para verificar si el usuario está dentro del campus
class CheckCampusStatusUseCase {
  /// Polígono del campus SENATI INDEPENDENCIA
  static final List<LocationEntity> campusPolygon = [
    LocationEntity(latitude: -11.997906073637472, longitude: -77.0624780466876),
    LocationEntity(latitude: -12.000650779873927, longitude: -77.06204828923563),
    LocationEntity(latitude: -12.000121147900016, longitude: -77.0583019566308),
    LocationEntity(latitude: -11.997358627864077, longitude: -77.05871520796907),
  ];

  /// Verifica si un punto está dentro del polígono del campus
  bool call(LocationEntity location) {
    return _pointInsideCampus(location.latitude, location.longitude);
  }

  bool _pointInsideCampus(double lat, double lon) {
    bool inside = false;

    for (int i = 0, j = campusPolygon.length - 1; i < campusPolygon.length; j = i++) {
      final double latI = campusPolygon[i].latitude;
      final double lonI = campusPolygon[i].longitude;
      final double latJ = campusPolygon[j].latitude;
      final double lonJ = campusPolygon[j].longitude;

      final bool intersect = ((latI > lat) != (latJ > lat)) &&
          (lon < (lonJ - lonI) * (lat - latI) / (latJ - latI) + lonI);

      if (intersect) inside = !inside;
    }

    return inside;
  }
}

