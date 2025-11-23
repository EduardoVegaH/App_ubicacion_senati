import '../../data/data_sources/notification_data_source.dart';
import '../../domain/entities/student_entity.dart';

/// Use case para programar notificaciones de cursos
class ScheduleNotificationsUseCase {
  final NotificationDataSource _notificationDataSource;

  ScheduleNotificationsUseCase(this._notificationDataSource);

  /// Programar notificaciones para una lista de cursos
  /// 
  /// Incluye:
  /// - Verificación de permisos
  /// - Programación de notificación de prueba
  /// - Programación de notificaciones para todos los cursos
  Future<void> call(List<CourseEntity> courses) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final hasPermissions = await _notificationDataSource.checkPermissions();
      if (!hasPermissions) {
        print('⚠️ ADVERTENCIA: Las notificaciones no están habilitadas');
      }

      // Programar notificación de prueba
      await _notificationDataSource.scheduleTestNotification(10);

      if (courses.isNotEmpty) {
        await _notificationDataSource.scheduleAllCourseNotifications(courses);
      }
    } catch (e) {
      print('Error programando notificaciones: $e');
    }
  }
}

