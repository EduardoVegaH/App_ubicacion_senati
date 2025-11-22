import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;

class SensorService {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magnetSub;

  List<double> accelerometer = [0, 0, 0];
  List<double> gyroscope = [0, 0, 0];
  List<double> magnetometer = [0, 0, 0];

  double heading = 0; // orientación final (azimuth del magnetómetro)
  double _lastRawHeading = 0;
  DateTime _lastUpdateTime = DateTime.now();
  double _lastHeadingValue = 0;
  int _stuckCounter = 0; // Contador para detectar si está congelado

  double posX = 0;
  double posY = 0;
  double stepLength = 0.6; // metros

  Function()? onDataChanged;

  // ---- DETECTAR PASO ----
  void _onStepDetected() {
    posX += stepLength * math.cos(heading);
    posY += stepLength * math.sin(heading);

    print("PASO → x:$posX  y:$posY  h:$heading");
  }

  // ---- INICIAR SENSORES ----
  void start() {
    // ACELERÓMETRO → detectar pasos
    _accelSub = accelerometerEventStream().listen((event) {
      accelerometer = [event.x, event.y, event.z];

      if (event.z > 12) {
        _onStepDetected();
      }

      _notify();
    });

    // GIROSCOPIO → no usado por ahora (puede causar drift)
    _gyroSub = gyroscopeEventStream().listen((event) {
      // Ignorado por ahora - solo usamos magnetómetro
    });

    // MAGNETÓMETRO + ACELERÓMETRO → calcular heading correctamente
    _magnetSub = magnetometerEventStream().listen((event) {
      magnetometer = [event.x, event.y, event.z];

      // Normalizar acelerómetro
      double ax = accelerometer[0];
      double ay = accelerometer[1];
      double az = accelerometer[2];
      double accNorm = math.sqrt(ax * ax + ay * ay + az * az);
      if (accNorm == 0) return;

      ax /= accNorm;
      ay /= accNorm;
      az /= accNorm;

      // Calcular pitch y roll
      double pitch = math.asin(-ax);
      double roll = math.atan2(ay, az);

      // Normalizar magnetómetro
      double mx = magnetometer[0];
      double my = magnetometer[1];
      double mz = magnetometer[2];
      double magNorm = math.sqrt(mx * mx + my * my + mz * mz);
      if (magNorm < 10) return; // Campo magnético muy débil, ignorar

      mx /= magNorm;
      my /= magNorm;
      mz /= magNorm;

      // Rotar magnetómetro según pitch y roll para obtener componentes horizontales
      // Compensación de inclinación para obtener el vector magnético horizontal
      double mx2 = mx * math.cos(pitch) + mz * math.sin(pitch);
      double my2 = mx * math.sin(roll) * math.sin(pitch) + 
                   my * math.cos(roll) - 
                   mz * math.sin(roll) * math.cos(pitch);

      // Calcular heading (azimuth) - dirección donde apunta el teléfono
      double rawHeading = math.atan2(my2, mx2);
      
      // CORRECCIÓN: Invertir 180 grados para que apunte correctamente
      rawHeading = rawHeading + math.pi;
      
      // Normalizar rawHeading a [-π, π]
      while (rawHeading > math.pi) rawHeading -= 2 * math.pi;
      while (rawHeading < -math.pi) rawHeading += 2 * math.pi;
      
      // Normalizar heading actual a [-π, π]
      double currentHeading = heading;
      while (currentHeading > math.pi) currentHeading -= 2 * math.pi;
      while (currentHeading < -math.pi) currentHeading += 2 * math.pi;
      
      // Calcular diferencia angular (considerando el wraparound de -π a π)
      // IMPORTANTE: Usar el camino más corto, incluso cuando das una vuelta completa
      double diff = rawHeading - currentHeading;
      
      // Normalizar diferencia a rango [-π, π] (siempre el camino más corto)
      // Esto es CRÍTICO para que funcione cuando das vueltas completas
      if (diff > math.pi) {
        diff -= 2 * math.pi;
      } else if (diff < -math.pi) {
        diff += 2 * math.pi;
      }

      // FILTRO ANTI-SALTOS: Solo rechazar cambios MUY bruscos (más de 90 grados)
      // Aumentado para permitir giros completos normales
      double maxAllowedDiff = 1.8; // radianes (~103 grados) - permite giros normales
      if (diff.abs() > maxAllowedDiff) {
        // Solo rechazar si es un salto realmente anormal
        return;
      }

      // DETECCIÓN DE CONGELAMIENTO: Verificar si la flecha está congelada
      DateTime now = DateTime.now();
      double headingChange = (heading - _lastHeadingValue).abs();
      
      // RECALIBRACIÓN AGRESIVA: Si hay una diferencia grande en el sensor pero la flecha no se mueve
      // Condición 1: El sensor detecta un cambio grande (>0.3 rad) pero la flecha no ha cambiado mucho
      // Condición 2: Han pasado más de 100ms desde la última actualización
      // Condición 3: La diferencia entre sensor y flecha es grande
      bool sensorMoving = diff.abs() > 0.3;
      bool arrowStuck = headingChange < 0.05; // La flecha apenas se mueve
      bool timePassed = now.difference(_lastUpdateTime).inMilliseconds > 100;
      bool bigGap = diff.abs() > 0.4; // Gran diferencia entre sensor y flecha
      
      // RECALIBRACIÓN FORZADA: Si el sensor se mueve pero la flecha está pegada
      bool needsRecalibration = sensorMoving && (arrowStuck || timePassed || bigGap);
      
      // Actualizar SIEMPRE que haya un cambio (aunque sea pequeño)
      // Esto hace que la flecha responda inmediatamente a donde miras
      if (diff.abs() > 0.02) {
        double newHeading;
        
        if (needsRecalibration) {
          // RECALIBRACIÓN FORZADA: Saltar directamente al rawHeading si está congelado
          newHeading = rawHeading;
          _stuckCounter = 0; // Resetear contador
        } else {
          // Aplicar filtro exponencial balanceado (0.35 = respuesta buena, fluida)
          double desiredChange = 0.35 * diff;
          
          // Limitar el cambio máximo por frame para evitar saltos
          double maxChangePerFrame = 0.1; // radianes por actualización
          if (desiredChange.abs() > maxChangePerFrame) {
            desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
          }
          
          newHeading = currentHeading + desiredChange;
        }
        
        // Normalizar heading resultante a [-π, π]
        while (newHeading > math.pi) newHeading -= 2 * math.pi;
        while (newHeading < -math.pi) newHeading += 2 * math.pi;
        
        // Verificar si realmente cambió (para detectar congelamiento)
        if ((newHeading - _lastHeadingValue).abs() > 0.01) {
          _lastUpdateTime = now;
          _lastHeadingValue = newHeading;
        }
        
        heading = newHeading;
        _lastRawHeading = rawHeading;
        _notify();
      }
    });
  }

  void _notify() {
    if (onDataChanged != null) onDataChanged!();
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magnetSub?.cancel();
  }
}
