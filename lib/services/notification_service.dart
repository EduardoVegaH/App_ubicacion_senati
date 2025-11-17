import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/student_model.dart';

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
        print('✅ Plugin de notificaciones inicializado correctamente');
        // Solicitar permisos en Android 13+
        try {
          final androidPlugin = _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          
          if (androidPlugin != null) {
            final granted = await androidPlugin.requestNotificationsPermission();
            print('🔔 Permiso de notificaciones: ${granted ? "CONCEDIDO" : "DENEGADO"}');
            
            if (!granted) {
              print('⚠️ ADVERTENCIA: Los permisos de notificaciones no fueron concedidos');
            }
          }
        } catch (e) {
          print('❌ Error al solicitar permisos de notificaciones: $e');
        }
      } else {
        print('❌ El plugin de notificaciones no se inicializó correctamente');
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
        print('🔔 Estado de permisos de notificaciones: ${granted ? "HABILITADAS" : "DESHABILITADAS"}');
        return granted ?? false;
      }
      return true; // En iOS o si no hay plugin, asumimos que está bien
    } catch (e) {
      print('❌ Error al verificar permisos: $e');
      return false;
    }
  }

  // Programar notificación para un curso
  static Future<void> scheduleCourseNotification(Course course) async {
    print('📅 Intentando programar notificación para: ${course.name}');
    
    // Verificar permisos primero
    final hasPermissions = await checkNotificationPermissions();
    if (!hasPermissions) {
      print('⚠️ ADVERTENCIA: Los permisos de notificaciones no están habilitados');
      print('💡 El usuario debe habilitar las notificaciones en la configuración del dispositivo');
    }
    
    final startTime = _parseTime(course.startTime);
    if (startTime == null) {
      print('❌ Error: No se pudo parsear el tiempo: ${course.startTime}');
      return;
    }

    // Calcular tiempo de notificación (10 minutos antes)
    final notificationTime = startTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();

    print('🕐 Hora actual: ${now.toString()}');
    print('🕐 Hora de inicio del curso: ${startTime.toString()}');
    print('🕐 Hora de notificación programada: ${notificationTime.toString()}');
    print('⏱️ Tiempo hasta la notificación: ${notificationTime.difference(now).inMinutes} minutos');

    // Solo programar si la notificación es en el futuro (hoy)
    if (notificationTime.isBefore(now)) {
      print('⚠️ La notificación ya pasó, no se programa');
      print('💡 Sugerencia: Verifica que la hora del dispositivo sea correcta');
      return;
    }

    print('✅ La notificación será en el futuro, programando...');

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

    // Programar la notificación
    try {
      final scheduledTime = tz.TZDateTime.from(notificationTime, tz.local);
      print('📲 Programando notificación para: ${scheduledTime.toString()}');
      print('📲 ID de notificación: ${course.name.hashCode}');
      
      // Intentar con exactAllowWhileIdle primero, si falla usar exact
      try {
        await _notifications.zonedSchedule(
          course.name.hashCode, // ID único basado en el nombre del curso
          'Próximo curso en 10 minutos',
          '${course.name}\n${course.startTime} - ${course.endTime}',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('✅ Notificación programada exitosamente (modo exactAllowWhileIdle) para ${course.name}');
      } catch (e) {
        print('⚠️ Error con exactAllowWhileIdle, intentando con modo exact: $e');
        // Si falla, intentar con modo exact
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
        print('✅ Notificación programada exitosamente (modo exact) para ${course.name}');
      }
    } catch (e) {
      print('❌ Error al programar notificación: $e');
      print('💡 Verifica:');
      print('   1. Que los permisos de notificaciones estén habilitados');
      print('   2. Que la hora del dispositivo sea correcta');
      print('   3. Que la app tenga permisos de "Programar alarmas exactas"');
    }
  }

  // Programar notificaciones para todos los cursos
  static Future<void> scheduleAllCourseNotifications(
      List<Course> courses) async {
    print('🔔 Iniciando programación de notificaciones para ${courses.length} cursos');
    for (var course in courses) {
      await scheduleCourseNotification(course);
    }
    print('✅ Programación de notificaciones completada');
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
      
      print('🧪 Programando notificación de prueba para: ${scheduledTime.toString()}');
      
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
      
      print('✅ Notificación de prueba programada exitosamente');
    } catch (e) {
      print('❌ Error al programar notificación de prueba: $e');
    }
  }
}

