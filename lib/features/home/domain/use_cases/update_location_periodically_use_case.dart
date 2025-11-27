import '../../data/data_sources/location_data_source.dart';
import '../../../../features/auth/domain/index.dart' as auth_domain;
import 'check_campus_status_use_case.dart';
import 'update_location_use_case.dart';

/// Use case para actualizar la ubicación periódicamente
/// 
/// Encapsula toda la lógica de:
/// - Obtener ubicación actual
/// - Verificar si está dentro del campus
/// - Obtener usuario actual
/// - Actualizar ubicación en Firestore
class UpdateLocationPeriodicallyUseCase {
  final LocationDataSource _locationDataSource;
  final CheckCampusStatusUseCase _checkCampusStatusUseCase;
  final UpdateLocationUseCase _updateLocationUseCase;
  final auth_domain.GetCurrentUserUseCase _getCurrentUserUseCase;

  UpdateLocationPeriodicallyUseCase(
    this._locationDataSource,
    this._checkCampusStatusUseCase,
    this._updateLocationUseCase,
    this._getCurrentUserUseCase,
  );

  /// Actualizar ubicación del usuario
  /// 
  /// Retorna:
  /// - `String?` con el estado del campus ("Dentro del campus" o "Fuera del campus")
  /// - `null` si no hay usuario autenticado o hay error
  Future<String?> call() async {
    try {
      final location = await _locationDataSource.getCurrentLocation();
      final isInside = _checkCampusStatusUseCase.call(location);
      
      final status = isInside ? "Dentro del campus" : "Fuera del campus";
      
      // Retornar el estado INMEDIATAMENTE antes de actualizar Firestore
      // Esto permite que la UI se actualice de forma más rápida
      
      final user = _getCurrentUserUseCase.call();
      if (user == null) return null;

      // Actualizar Firestore en background (no bloquear la respuesta)
      _updateLocationUseCase.call(
        userId: user.uid,
        location: location,
        campusStatus: status,
      ).catchError((e) {
        print("Error actualizando ubicación en Firestore: $e");
        // No re-lanzar el error, solo loguearlo
      });

      return status;
    } catch (e) {
      print("Error actualizando ubicación: $e");
      return null;
    }
  }
}

