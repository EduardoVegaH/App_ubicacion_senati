import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/location_entity.dart';

/// Fuente de datos para ubicación
class LocationDataSource {
  /// Obtener ubicación actual
  Future<LocationEntity> getCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

