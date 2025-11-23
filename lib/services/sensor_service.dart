import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class SensorService {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magnetSub;

  List<double> accelerometer = [0, 0, 0];
  List<double> gyroscope = [0, 0, 0];
  List<double> magnetometer = [0, 0, 0];
  
  // Acelerómetro suavizado para el cálculo del heading (evita interferencia al caminar)
  List<double> _smoothedAccel = [0, 0, 9.8];
  double _accelSmoothing = 0.95; // Factor de suavizado (0.95 = muy suave)
  
  // Pitch y roll estables para usar cuando caminas
  double _stablePitch = 0;
  double _stableRoll = 0;
  List<double> _pitchHistory = [];
  List<double> _rollHistory = [];
  
  // Historial de headings para suavizar cuando caminas
  List<double> _headingHistory = [];
  static const int _headingHistorySize = 10;
  
  // Giroscopio para detectar giros bruscos
  List<double> _gyroHistory = [];
  DateTime _lastGyroUpdate = DateTime.now();
  double _gyroMagnitudeThreshold = 2.0; // rad/s - umbral para giro brusco
  bool _gyroRotationDetected = false; // Flag: giroscopio detectó rotación
  DateTime _lastGyroRotation = DateTime.now();
  static const Duration _gyroRotationTimeout = Duration(milliseconds: 300); // Tiempo que el flag permanece activo (más corto para mayor precisión)
  
  // Calibración del magnetómetro (estilo Google Maps - movimiento en "8")
  List<List<double>> _magCalibrationData = []; // Datos para calibración
  List<double> _magOffset = [0, 0, 0]; // Offset de calibración
  List<double> _magScale = [1, 1, 1]; // Escala de calibración
  bool _isMagCalibrated = false;
  
  // Ubicación para calcular declinación magnética
  double? _latitude;
  double? _longitude;
  double _magneticDeclination = 0.0; // Declinación magnética en radianes
  DateTime _lastLocationUpdate = DateTime(1970);
  static const Duration _locationUpdateInterval = Duration(minutes: 5); // Actualizar ubicación cada 5 minutos
  DateTime _calibrationStartTime = DateTime.now();
  static const int _calibrationSamplesNeeded = 100; // Muestras necesarias para calibración inicial (aumentado para mejor precisión)
  static const int _calibrationSamplesNeededFast = 50; // Muestras para recalibración rápida después de giro
  static const int _maxCalibrationSamples = 300; // Máximo de muestras a mantener (aumentado para mejor calibración)
  DateTime _lastCalibrationUpdate = DateTime.now();
  static const Duration _calibrationUpdateInterval = Duration(seconds: 3); // Actualizar calibración cada 3 segundos (más frecuente)
  static const Duration _calibrationUpdateIntervalFast = Duration(milliseconds: 300); // Actualizar calibración rápida cada 300ms
  bool _fastCalibrationMode = false; // Modo de calibración rápida después de giro
  
  // Calcular calibración del magnetómetro (método de esfera mínima - CALIBRACIÓN CONTINUA)
  void _calibrateMagnetometer() {
    int samplesNeeded = _fastCalibrationMode ? _calibrationSamplesNeededFast : _calibrationSamplesNeeded;
    if (_magCalibrationData.length < samplesNeeded) return;
    
    // Calcular min y max de cada eje
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    double minZ = double.infinity, maxZ = -double.infinity;
    
    for (var sample in _magCalibrationData) {
      if (sample[0] < minX) minX = sample[0];
      if (sample[0] > maxX) maxX = sample[0];
      if (sample[1] < minY) minY = sample[1];
      if (sample[1] > maxY) maxY = sample[1];
      if (sample[2] < minZ) minZ = sample[2];
      if (sample[2] > maxZ) maxZ = sample[2];
    }
    
    // Calcular offset (centro de la esfera)
    double newOffsetX = (minX + maxX) / 2;
    double newOffsetY = (minY + maxY) / 2;
    double newOffsetZ = (minZ + maxZ) / 2;
    
    // Calcular escala (radio promedio)
    double rangeX = maxX - minX;
    double rangeY = maxY - minY;
    double rangeZ = maxZ - minZ;
    double avgRadius = (rangeX + rangeY + rangeZ) / 6;
    
    double newScaleX = 1.0, newScaleY = 1.0, newScaleZ = 1.0;
    if (avgRadius > 0 && rangeX > 0) {
      newScaleX = avgRadius / (rangeX / 2);
    }
    if (avgRadius > 0 && rangeY > 0) {
      newScaleY = avgRadius / (rangeY / 2);
    }
    if (avgRadius > 0 && rangeZ > 0) {
      newScaleZ = avgRadius / (rangeZ / 2);
    }
    
    // ACTUALIZACIÓN CONTINUA: Suavizar los valores de calibración (filtro adaptativo)
    // Esto permite que la calibración se actualice continuamente sin saltos bruscos
    // Reducir el suavizado para que corrija desvíos más rápidamente
    double smoothingFactor = _isMagCalibrated ? 0.3 : 1.0; // Mucho menos suave para corregir desvíos más rápido y mejor
    
    _magOffset[0] = smoothingFactor * _magOffset[0] + (1 - smoothingFactor) * newOffsetX;
    _magOffset[1] = smoothingFactor * _magOffset[1] + (1 - smoothingFactor) * newOffsetY;
    _magOffset[2] = smoothingFactor * _magOffset[2] + (1 - smoothingFactor) * newOffsetZ;
    
    _magScale[0] = smoothingFactor * _magScale[0] + (1 - smoothingFactor) * newScaleX;
    _magScale[1] = smoothingFactor * _magScale[1] + (1 - smoothingFactor) * newScaleY;
    _magScale[2] = smoothingFactor * _magScale[2] + (1 - smoothingFactor) * newScaleZ;
    
    _isMagCalibrated = true;
  }

  double heading = 0; // orientación final (azimuth del magnetómetro)
  double _lastRawHeading = 0;
  DateTime _lastUpdateTime = DateTime.now();
  double _lastHeadingValue = 0;
  int _stuckCounter = 0; // Contador para detectar si está congelado
  
  // Recalibración automática
  DateTime _lastCalibrationTime = DateTime.now();
  bool _needsCalibration = false;
  
  // Detección de movimiento para estabilizar brújula
  DateTime _lastStepDetected = DateTime.now();
  bool _isWalking = false;
  
  // Detección de caminata en línea recta (misma dirección que la flecha)
  List<double> _recentHeadingChanges = []; // Cambios recientes de heading mientras caminas
  static const int _headingChangeHistorySize = 10;
  bool _isWalkingStraight = false; // Flag: caminando en línea recta

  double posX = 0;
  double posY = 0;
  double stepLength = 0.6; // metros

  Function()? onDataChanged;
  
  // Método público para recalibrar manualmente
  void recalibrate() {
    _needsCalibration = true;
    _lastCalibrationTime = DateTime.now();
    print("🔄 Recalibración iniciada");
  }
  
  // Actualizar ubicación para calcular declinación magnética
  Future<void> updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
      _magneticDeclination = _calculateMagneticDeclination(_latitude!, _longitude!);
      _lastLocationUpdate = DateTime.now();
      print("📍 Ubicación actualizada: lat=${_latitude!.toStringAsFixed(6)}, lon=${_longitude!.toStringAsFixed(6)}, declinación=${(_magneticDeclination * 180 / math.pi).toStringAsFixed(2)}°");
    } catch (e) {
      print("⚠️ Error al obtener ubicación: $e");
    }
  }
  
  // Calcular declinación magnética basada en latitud y longitud
  // Fórmula aproximada basada en el modelo IGRF (International Geomagnetic Reference Field)
  double _calculateMagneticDeclination(double lat, double lon) {
    // Convertir a radianes
    double latRad = lat * math.pi / 180.0;
    double lonRad = lon * math.pi / 180.0;
    
    // Fórmula simplificada para declinación magnética
    // Para Perú (aproximadamente -12° lat, -77° lon), la declinación es aproximadamente -1° a -2°
    // Fórmula más precisa basada en aproximación del modelo IGRF
    
    // Año actual para ajuste temporal (la declinación cambia con el tiempo)
    int year = DateTime.now().year;
    double yearFraction = (year - 2020) / 100.0; // Cambio anual aproximado
    
    // Cálculo aproximado de declinación magnética
    // Para latitudes negativas (sur) y longitudes negativas (oeste)
    double declination = 0.0;
    
    // Aproximación simple: para Perú, la declinación es aproximadamente -1.5° a -2°
    // Ajustar según latitud y longitud
    if (lat < 0 && lon < 0) {
      // Hemisferio sur, oeste
      declination = -0.03 + (lat * 0.0001) + (lon * 0.0001); // Aproximación
      declination += yearFraction * 0.0001; // Ajuste temporal
    } else {
      // Fórmula general aproximada
      declination = math.atan2(
        math.sin(lonRad) * math.cos(latRad),
        math.cos(latRad) * math.cos(lonRad) - math.sin(latRad)
      );
    }
    
    // Normalizar a rango [-π, π]
    while (declination > math.pi) declination -= 2 * math.pi;
    while (declination < -math.pi) declination += 2 * math.pi;
    
    return declination;
  }

  // ---- DETECCIÓN DE PASOS ----
  DateTime _lastStepTime = DateTime.now();
  double _lastAccelZ = 9.8;
  double _minStepInterval = 0.3; // Segundos mínimos entre pasos

  // ---- DETECTAR PASO ----
  void _onStepDetected() {
    DateTime now = DateTime.now();
    
    // Verificar que haya pasado el tiempo mínimo entre pasos
    if (now.difference(_lastStepTime).inMilliseconds < (_minStepInterval * 1000)) {
      return;
    }

    _lastStepTime = now;
    _lastStepDetected = now;
    _isWalking = true;
    print("🚶 Caminando detectado - brújula bloqueada");

    // AVANZAR en la dirección del heading actual - SOLO modifica posX y posY
    // CORRECCIÓN: El heading puede estar desfasado, ajustar según el sistema de coordenadas
    // En sistemas de coordenadas de pantalla:
    // - heading = 0° (norte) → debe moverse hacia arriba (Y negativo)
    // - heading = 90° (este) → debe moverse hacia la derecha (X positivo)
    // Si el heading está desfasado 90°, usar sin/cos intercambiados
    double moveX = stepLength * math.sin(heading); // Intercambiado: sin para X
    double moveY = -stepLength * math.cos(heading); // Intercambiado: -cos para Y (arriba)

    // Movimiento directo sin suavizado excesivo para que avance claramente
    posX = posX + moveX;
    posY = posY + moveY;

    // Notificar que la posición cambió
    _notify();

    print("PASO → x:${posX.toStringAsFixed(2)}  y:${posY.toStringAsFixed(2)}  heading:${(heading * 180 / math.pi).toStringAsFixed(1)}°");
  }

  // ---- INICIAR SENSORES ----
  void start() {
    // Reinicializar variables de detección de pasos
    _lastStepTime = DateTime.now();
    _lastAccelZ = 9.8;
    
    // Inicializar calibración del magnetómetro
    _magCalibrationData.clear();
    _isMagCalibrated = false;
    _calibrationStartTime = DateTime.now();
    _magOffset = [0, 0, 0];
    _magScale = [1, 1, 1];
    
    // Obtener ubicación inicial para calcular declinación magnética
    updateLocation();

    // ACELERÓMETRO → detectar pasos (SOLO para mover la flecha, NO toca la brújula)
    _accelSub = accelerometerEventStream().listen((event) {
      accelerometer = [event.x, event.y, event.z];
      
      // Suavizar acelerómetro para el cálculo del heading (evita interferencia al caminar)
      _smoothedAccel[0] = _accelSmoothing * _smoothedAccel[0] + (1 - _accelSmoothing) * event.x;
      _smoothedAccel[1] = _accelSmoothing * _smoothedAccel[1] + (1 - _accelSmoothing) * event.y;
      _smoothedAccel[2] = _accelSmoothing * _smoothedAccel[2] + (1 - _accelSmoothing) * event.z;

      // Detección más sensible: cuando z sube por encima de 10.5 (más bajo = más sensible)
      // Esto detecta el impacto del pie al caminar
      if (event.z > 10.5 && _lastAccelZ <= 10.5) {
        _onStepDetected();
      }
      _lastAccelZ = event.z;

      // NO llamar _notify() aquí para evitar actualizaciones innecesarias
      // Solo se notifica cuando realmente hay un paso
    });

    // GIROSCOPIO → detectar CUALQUIER rotación para actualizar brújula inmediatamente
    _gyroSub = gyroscopeEventStream().listen((event) {
      gyroscope = [event.x, event.y, event.z];
      
      // Calcular magnitud del giroscopio (velocidad angular)
      double gyroMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      DateTime now = DateTime.now();
      
      // Detectar CUALQUIER rotación (umbral más bajo para detectar giros más precisos)
      double rotationThreshold = 0.3; // rad/s - umbral más bajo para detectar giros más precisos
      if (gyroMagnitude > rotationThreshold) {
        // CUALQUIER rotación detectada - activar flag para actualizar brújula con mayor precisión
        _gyroRotationDetected = true;
        _lastGyroRotation = now;
      }
      
      // Desactivar flag después del timeout si no hay más rotación (timeout más corto para mayor precisión)
      if (_gyroRotationDetected && now.difference(_lastGyroRotation) > _gyroRotationTimeout) {
        _gyroRotationDetected = false;
      }
      
      // Detectar giro brusco (rotación rápida del teléfono) para RECALIBRACIÓN INSTANTÁNEA
      if (gyroMagnitude > _gyroMagnitudeThreshold) {
        // Giro brusco detectado - RECALIBRACIÓN INSTANTÁNEA
        print("🔄 Giro brusco detectado (${gyroMagnitude.toStringAsFixed(2)} rad/s) - Recalibrando INSTANTÁNEAMENTE");
        
        // Limpiar calibración anterior y forzar recalibración inmediata
        _needsCalibration = true;
        _lastCalibrationTime = DateTime(1970); // Forzar recalibración inmediata
        _isMagCalibrated = false; // Recalibrar magnetómetro también
        _magCalibrationData.clear(); // Limpiar datos antiguos
        _calibrationStartTime = now;
        
        // Acelerar recolección de muestras para recalibración rápida
        // Reducir el número de muestras necesarias para recalibración rápida
      }
      
      _lastGyroUpdate = now;
    });

    // MAGNETÓMETRO + ACELERÓMETRO → calcular heading correctamente
    _magnetSub = magnetometerEventStream().listen((event) {
      magnetometer = [event.x, event.y, event.z];

      // Usar acelerómetro SUAVIZADO para calcular pitch y roll
      // Esto evita que el movimiento al caminar afecte el cálculo del heading
      double ax = _smoothedAccel[0];
      double ay = _smoothedAccel[1];
      double az = _smoothedAccel[2];
      double accNorm = math.sqrt(ax * ax + ay * ay + az * az);
      if (accNorm == 0) return;

      ax /= accNorm;
      ay /= accNorm;
      az /= accNorm;

      // Calcular pitch y roll
      double pitch = math.asin(-ax);
      double roll = math.atan2(ay, az);
      
      // Cuando estás caminando, usar valores FIJOS de pitch/roll guardados cuando estabas quieto
      // Esto evita completamente que el movimiento afecte el cálculo del heading
      if (_isWalking) {
        // Usar valores estables guardados (calculados cuando estabas quieto)
        if (_pitchHistory.isNotEmpty && _rollHistory.isNotEmpty) {
          pitch = _stablePitch;
          roll = _stableRoll;
        }
        // NO actualizar el historial cuando caminas
      } else {
        // Cuando estás QUIETO, actualizar el historial y guardar valores estables
        _pitchHistory.add(pitch);
        _rollHistory.add(roll);
        if (_pitchHistory.length > 30) _pitchHistory.removeAt(0);
        if (_rollHistory.length > 30) _rollHistory.removeAt(0);
        
        // Calcular y guardar valores estables (promedio del historial)
        if (_pitchHistory.length >= 10) {
          _stablePitch = _pitchHistory.reduce((a, b) => a + b) / _pitchHistory.length;
          _stableRoll = _rollHistory.reduce((a, b) => a + b) / _rollHistory.length;
        }
      }

      DateTime now = DateTime.now();
      
      // CALIBRACIÓN CONTINUA DEL MAGNETÓMETRO (estilo Google Maps - movimiento en "8")
      // Siempre recolectar muestras para calibración continua
      // Detectar movimiento variado (como el "8") automáticamente
      double magVariation = math.sqrt(
        math.pow(magnetometer[0] - (_magCalibrationData.isNotEmpty ? _magCalibrationData.last[0] : magnetometer[0]), 2) +
        math.pow(magnetometer[1] - (_magCalibrationData.isNotEmpty ? _magCalibrationData.last[1] : magnetometer[1]), 2) +
        math.pow(magnetometer[2] - (_magCalibrationData.isNotEmpty ? _magCalibrationData.last[2] : magnetometer[2]), 2)
      );
      
      // Recolectar muestras continuamente (más agresivo para mejor calibración)
      bool shouldCollectSample = true;
      if (_magCalibrationData.length > _calibrationSamplesNeeded) {
        // Si ya tenemos suficientes muestras, agregar si hay variación o cada cierto tiempo
        // Reducir umbral de variación para capturar más muestras
        shouldCollectSample = magVariation > 2.0 || now.difference(_lastCalibrationUpdate) > Duration(seconds: 1);
      }
      
      // Recolectar muestras más frecuentemente para mejor calibración
      if (shouldCollectSample) {
        _magCalibrationData.add([magnetometer[0], magnetometer[1], magnetometer[2]]);
        if (_magCalibrationData.length > _maxCalibrationSamples) {
          _magCalibrationData.removeAt(0); // Mantener solo las últimas muestras
        }
      }
      
      // Actualizar calibración periódicamente o cuando hay suficientes muestras nuevas
      bool shouldUpdateCalibration = false;
      int samplesNeeded = _fastCalibrationMode ? _calibrationSamplesNeededFast : _calibrationSamplesNeeded;
      Duration updateInterval = _fastCalibrationMode ? _calibrationUpdateIntervalFast : _calibrationUpdateInterval;
      
      if (_magCalibrationData.length >= samplesNeeded) {
        if (!_isMagCalibrated) {
          // Primera calibración: hacerla inmediatamente
          shouldUpdateCalibration = true;
        } else if (now.difference(_lastCalibrationUpdate) >= updateInterval) {
          // Calibración continua: actualizar según el modo (rápido o normal)
          shouldUpdateCalibration = true;
        } else if (_needsCalibration) {
          // Recalibración forzada (por giro brusco) - MODO RÁPIDO
          shouldUpdateCalibration = true;
          _fastCalibrationMode = true; // Activar modo rápido
        }
      }
      
      // SIEMPRE actualizar calibración si tenemos suficientes muestras y no está calibrado
      if (!_isMagCalibrated && _magCalibrationData.length >= samplesNeeded) {
        shouldUpdateCalibration = true;
      }
      
      if (shouldUpdateCalibration) {
        _calibrateMagnetometer();
        _lastCalibrationUpdate = now;
        // NO desactivar _needsCalibration aquí - se usará para actualización rápida del heading
        // Se desactivará después de actualizar el heading
        
        // Desactivar modo rápido después de 3 segundos
        if (_fastCalibrationMode && now.difference(_calibrationStartTime).inSeconds > 3) {
          _fastCalibrationMode = false;
        }
      }
      
      // Aplicar calibración al magnetómetro
      double mx = magnetometer[0];
      double my = magnetometer[1];
      double mz = magnetometer[2];
      
      if (_isMagCalibrated) {
        // Aplicar offset y escala
        mx = (mx - _magOffset[0]) * _magScale[0];
        my = (my - _magOffset[1]) * _magScale[1];
        mz = (mz - _magOffset[2]) * _magScale[2];
      }
      
      // Normalizar magnetómetro calibrado
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
      
      // CORRECCIÓN: Ajustar según la orientación del dispositivo
      // Rotación base de 180° para alinear con el sistema de coordenadas
      rawHeading = rawHeading + math.pi;
      
      // Aplicar declinación magnética basada en latitud y longitud
      // Actualizar ubicación periódicamente
      if (_latitude == null || _longitude == null || 
          DateTime.now().difference(_lastLocationUpdate) > _locationUpdateInterval) {
        updateLocation(); // Actualizar ubicación en segundo plano
      }
      
      // Aplicar declinación magnética si tenemos ubicación
      if (_latitude != null && _longitude != null) {
        rawHeading = rawHeading - _magneticDeclination; // Restar declinación para corregir
      } else {
        // Si no tenemos ubicación, usar offset fijo aproximado para Perú
        rawHeading = rawHeading - 0.025; // -0.025 rad ≈ -1.4° (declinación aproximada para Perú)
      }
      
      // Normalizar rawHeading a [-π, π]
      while (rawHeading > math.pi) rawHeading -= 2 * math.pi;
      while (rawHeading < -math.pi) rawHeading += 2 * math.pi;
      
      // Normalizar heading actual a [-π, π] (declarar ANTES de usarlo)
      double currentHeading = heading;
      while (currentHeading > math.pi) currentHeading -= 2 * math.pi;
      while (currentHeading < -math.pi) currentHeading += 2 * math.pi;
      
      // Si se necesita recalibración forzada (por giro brusco) Y está en modo rápido, actualizar heading más agresivamente
      // Esto permite que la brújula se actualice instantáneamente después de un giro
      bool wasFastCalibration = false;
      if (_needsCalibration && _isMagCalibrated && _fastCalibrationMode) {
        // En modo de calibración rápida, actualizar heading más agresivamente
        // Usar rawHeading con filtro muy suave para actualización instantánea
        double filterStrength = 0.8; // Filtro muy suave para actualización rápida
        double desiredChange = rawHeading - currentHeading;
        // Normalizar diferencia
        if (desiredChange > math.pi) desiredChange -= 2 * math.pi;
        if (desiredChange < -math.pi) desiredChange += 2 * math.pi;
        
        heading = currentHeading + (desiredChange * filterStrength);
        // Normalizar
        while (heading > math.pi) heading -= 2 * math.pi;
        while (heading < -math.pi) heading += 2 * math.pi;
        
        _lastHeadingValue = heading;
        _lastUpdateTime = now;
        _lastRawHeading = rawHeading;
        _notify();
        wasFastCalibration = true;
        _needsCalibration = false; // Desactivar después de actualizar
        // NO retornar - continuar con el flujo normal para aplicar calibración continua
      }
      
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

      // Detectar si estás caminando
      _isWalking = now.difference(_lastStepDetected).inSeconds < 2;
      
      // Detectar si estás caminando en línea recta (misma dirección que la flecha)
      // Esto causa interferencia que hace que la brújula se desvíe hacia la derecha
      if (_isWalking && !_gyroRotationDetected) {
        // Guardar cambios recientes de heading mientras caminas
        _recentHeadingChanges.add(diff.abs());
        if (_recentHeadingChanges.length > _headingChangeHistorySize) {
          _recentHeadingChanges.removeAt(0);
        }
        
        // Si los cambios de heading son muy pequeños y consistentes, estás caminando en línea recta
        if (_recentHeadingChanges.length >= 5) {
          double avgChange = _recentHeadingChanges.reduce((a, b) => a + b) / _recentHeadingChanges.length;
          // Si el cambio promedio es muy pequeño (<0.15 rad = ~9°), estás caminando en línea recta
          _isWalkingStraight = avgChange < 0.15;
        } else {
          _isWalkingStraight = false;
        }
      } else {
        // Limpiar historial cuando no estás caminando o hay giro detectado
        _recentHeadingChanges.clear();
        _isWalkingStraight = false;
      }
      
      // ACTUALIZACIÓN DE BRÚJULA
      if (diff.abs() > 0.01) {
        double newHeading;
        
        // Aplicar filtros normalmente, pero si el giroscopio detecta giro, actualizar más rápido
        if (_isWalking) {
          // BLOQUEO TOTAL cuando caminas en línea recta (misma dirección que la flecha)
          // Esto evita que la interferencia del movimiento desvíe la brújula hacia la derecha
          if (_isWalkingStraight && !_gyroRotationDetected) {
            // Caminando en línea recta - BLOQUEO TOTAL de la brújula
            // NO cambiar el heading para nada - mantenerlo completamente fijo
            newHeading = currentHeading; // BLOQUEO TOTAL
            print("🚫 Caminando en línea recta - Brújula bloqueada completamente");
          }
          // Giro detectado mientras caminas - actualizar MÁS PRECISO Y RÁPIDO
          else if (_gyroRotationDetected) {
            // Cuando el giroscopio detecta giro, ser más preciso y responsivo
            double filterStrength = 0.75; // Filtro más fuerte para mayor precisión
            double desiredChange = filterStrength * diff;
            double maxChangePerFrame = 0.25; // Permitir cambios más rápidos y precisos cuando hay giro
            if (desiredChange.abs() > maxChangePerFrame) {
              desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
            }
            newHeading = currentHeading + desiredChange;
          } else {
            // Sin giro detectado y no caminando en línea recta - bloqueo ligero normal cuando caminas
            if (diff.abs() > 0.3) {
              // Cambio grande = posible giro real, permitir con filtro moderado
              double filterStrength = 0.3; // Filtro más restrictivo
              double desiredChange = filterStrength * diff;
              double maxChangePerFrame = 0.08; // Cambio máximo muy limitado
              if (desiredChange.abs() > maxChangePerFrame) {
                desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
              }
              newHeading = currentHeading + desiredChange;
            } else {
              // Cambio pequeño = ruido del movimiento, bloquear casi completamente
              newHeading = currentHeading + (diff * 0.05); // Bloqueo muy restrictivo
            }
          }
        } 
        // Cuando estás quieto, filtro normal y responsivo
        else {
          if (_gyroRotationDetected) {
            // Giro detectado cuando estás quieto - actualizar MÁS PRECISO Y RÁPIDO
            double filterStrength = 0.85; // Filtro muy fuerte para máxima precisión
            double desiredChange = filterStrength * diff;
            double maxChangePerFrame = 0.3; // Permitir cambios más rápidos y precisos cuando hay giro
            if (desiredChange.abs() > maxChangePerFrame) {
              desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
            }
            newHeading = currentHeading + desiredChange;
          } else {
            // Sin giro detectado - filtro normal
            double filterStrength = 0.6; // Más responsivo cuando estás quieto
            double desiredChange = filterStrength * diff;
            
            double maxChangePerFrame = 0.2; // Permitir cambios más rápidos cuando estás quieto
            if (desiredChange.abs() > maxChangePerFrame) {
              desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
            }
            
            newHeading = currentHeading + desiredChange;
          }
        }
        
        // Normalizar heading resultante a [-π, π]
        while (newHeading > math.pi) newHeading -= 2 * math.pi;
        while (newHeading < -math.pi) newHeading += 2 * math.pi;
        
        heading = newHeading;
        _lastHeadingValue = newHeading;
        _lastUpdateTime = now;
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
