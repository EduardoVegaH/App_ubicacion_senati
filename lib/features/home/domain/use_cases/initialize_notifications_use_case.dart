import '../../data/data_sources/notification_data_source.dart';

/// Use case para inicializar el servicio de notificaciones
class InitializeNotificationsUseCase {
  final NotificationDataSource _notificationDataSource;

  InitializeNotificationsUseCase(this._notificationDataSource);

  /// Inicializar el servicio de notificaciones
  Future<void> call() async {
    await _notificationDataSource.initialize();
  }
}

