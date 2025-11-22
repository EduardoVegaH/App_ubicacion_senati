import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    //1. Verifica que el GPS este activado
    bool servicenEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicenEnabled) {
      throw Exception('El GPS esta desactivado.');
    }

    //2. Verifica los permisos de unicacion
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('El usuario denegó los permisos de ubicación.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Los permisos de ubicación están bloqueados permanentemente. '
        'Activa desde configuracion.',
      );
    }

    //3. Obtener la ubicaion real del dispositivo
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}