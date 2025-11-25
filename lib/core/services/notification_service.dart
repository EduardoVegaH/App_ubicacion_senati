import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'notification_service_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Configuración para Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Manejar cuando el usuario toca la notificación
        },
      ).catchError((error) {
        print('Error al inicializar plugin de notificaciones: $error');
        return false;
      });

      if (initialized == true) {
        try {
          final androidPlugin = _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          
          if (androidPlugin != null) {
            await androidPlugin.requestNotificationsPermission();
          }
        } catch (e) {
          print('Error al solicitar permisos de notificaciones: $e');
        }
      }
    } catch (e) {
      print('Error en NotificationService.initialize: $e');
      rethrow;
    }
  }

  // Función para parsear tiempo de formato "7:00 AM" a DateTime
  static DateTime? _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) {
        return null;
      }

      final timePart = parts[0]; // "7:00"
      final amPm = parts[1].toUpperCase(); // "AM" o "PM"

      final timeParts = timePart.split(':');
      if (timeParts.length != 2) {
        return null;
      }

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Convertir a formato 24 horas
      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Verificar permisos de notificaciones
  static Future<bool> checkNotificationPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.areNotificationsEnabled();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      print('Error al verificar permisos: $e');
      return false;
    }
  }

  // Programar notificación para un curso
  static Future<void> scheduleCourseNotification(Course course) async {
    await checkNotificationPermissions();
    
    final startTime = _parseTime(course.startTime);
    if (startTime == null) {
      return;
    }

    final notificationTime = startTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();

    if (notificationTime.isBefore(now)) {
      return;
    }

    // Cancelar notificaciones anteriores del mismo curso
    await cancelNotification(course.name.hashCode);

    // Configuración para Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'course_reminders',
      'Recordatorios de Cursos',
      channelDescription: 'Notificaciones para recordar cursos próximos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // Configuración para iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledTime = tz.TZDateTime.from(notificationTime, tz.local);
      
      try {
        await _notifications.zonedSchedule(
          course.name.hashCode,
          'Próximo curso en 10 minutos',
          '${course.name}\n${course.startTime} - ${course.endTime}',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        await _notifications.zonedSchedule(
          course.name.hashCode,
          'Próximo curso en 10 minutos',
          '${course.name}\n${course.startTime} - ${course.endTime}',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      print('Error al programar notificación: $e');
    }
  }

  // Programar notificaciones para todos los cursos
  static Future<void> scheduleAllCourseNotifications(
      List<Course> courses) async {
    for (var course in courses) {
      await scheduleCourseNotification(course);
    }
  }

  // Cancelar una notificación específica
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Función de prueba: programar una notificación en X segundos
  static Future<void> scheduleTestNotification(int secondsFromNow) async {
    try {
      final now = DateTime.now();
      final testTime = now.add(Duration(seconds: secondsFromNow));
      final scheduledTime = tz.TZDateTime.from(testTime, tz.local);
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'course_reminders',
        'Recordatorios de Cursos',
        channelDescription: 'Notificaciones para recordar cursos próximos',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        999999, // ID de prueba
        '🧪 Notificación de Prueba',
        'Esta es una notificación de prueba programada para $secondsFromNow segundos',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error al programar notificación de prueba: $e');
    }
  }
}

