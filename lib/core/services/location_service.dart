import 'dart:async';
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

    //3. Obtener la ubicaion real del dispositivo con timeout
    // Intentar obtener ubicación con timeout de 10 segundos
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout de 10 segundos
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Si timeout, intentar usar última ubicación conocida
          throw TimeoutException('Timeout obteniendo ubicación GPS');
        },
      );
    } on TimeoutException {
      // Si hay timeout, usar última ubicación conocida como fallback
      // NO imprimir error aquí, solo usar fallback silenciosamente
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        // Aumentar tolerancia de edad (máximo 5 minutos = 300 segundos)
        // Esto evita errores cuando el GPS tarda pero hay una ubicación reciente
        final age = DateTime.now().difference(lastPosition.timestamp);
        if (age.inSeconds < 300) {
          // Usar última ubicación conocida sin imprimir error
          return lastPosition;
        }
      }
      // Solo relanzar si realmente no hay ubicación disponible
      // Pero no imprimir aquí, dejar que el caller maneje el error
      rethrow;
    }
  }
}