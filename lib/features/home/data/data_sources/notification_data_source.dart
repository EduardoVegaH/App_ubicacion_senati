import '../../../../core/services/notification_service.dart';
import '../../../../core/services/notification_service_helper.dart';
import '../../domain/entities/student_entity.dart';

/// Fuente de datos para notificaciones
class NotificationDataSource {
  /// Inicializar notificaciones
  Future<void> initialize() async {
    await NotificationService.initialize();
  }

  /// Verificar permisos
  Future<bool> checkPermissions() async {
    return await NotificationService.checkNotificationPermissions();
  }

  /// Programar notificación de prueba
  Future<void> scheduleTestNotification(int seconds) async {
    await NotificationService.scheduleTestNotification(seconds);
  }

  /// Programar notificaciones para todos los cursos
  Future<void> scheduleAllCourseNotifications(List<CourseEntity> courses) async {
    // Convertir CourseEntity a Course temporal (NotificationService usa modelo antiguo)
    final oldCourses = courses.map((c) {
      return Course(
        name: c.name,
        type: c.type,
        startTime: c.startTime,
        endTime: c.endTime,
        duration: '',
        teacher: c.teacher,
        locationCode: c.locationCode,
        locationDetail: c.locationDetail,
        classroomLatitude: c.classroomLatitude,
        classroomLongitude: c.classroomLongitude,
        classroomRadius: c.classroomRadius,
      );
    }).toList();
    
    await NotificationService.scheduleAllCourseNotifications(oldCourses);
  }
}

