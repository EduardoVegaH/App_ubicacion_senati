import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'features/navigation/data/services/navigation_auto_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar inyección de dependencias
  await di.init();

  // Inicializar automáticamente los nodos y edges de navegación
  _initializeNavigationInBackground();

  runApp(const App());
}

/// Inicializa los nodos y edges de navegación en background
/// No bloquea el inicio de la app
void _initializeNavigationInBackground() {
  // Ejecutar en un microtask para no bloquear el main
  Future.microtask(() async {
    try {
      final autoInitializer = di.sl<NavigationAutoInitializer>();
      await autoInitializer.initializeIfNeeded();
    } catch (e) {
      print('⚠️ Error en inicialización automática de navegación: $e');
      // No lanzar error, solo loguear - la app debe seguir funcionando
    }
  });
}
