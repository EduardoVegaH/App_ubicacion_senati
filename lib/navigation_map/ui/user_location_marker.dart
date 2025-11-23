import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../models/map_node.dart';
import '../utils/map_scale_converter.dart';

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
  double _gyroMagnitudeThreshold = 1.5; // rad/s - umbral más bajo para detectar giros más rápido
  bool _gyroRotationDetected = false; // Flag: giroscopio detectó rotación
  DateTime _lastGyroRotation = DateTime.now();
  static const Duration _gyroRotationTimeout = Duration(milliseconds: 500); // Tiempo que el flag permanece activo (aumentado para mejor detección)
  
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
  double stepLength = 1.0; // metros (AUMENTADO para hacer el movimiento más visible)

  Function()? onDataChanged;
  
  // Método público para recalibrar manualmente
  void recalibrate() {
    _needsCalibration = true;
    _lastCalibrationTime = DateTime.now();
    print("🔄 Recalibración iniciada");
  }
  
  // Modo de calibración manual
  bool _manualCalibrationMode = false;
  
  // Método público para iniciar calibración manual estilo Google Maps
  void startManualCalibration() {
    // Limpiar datos de calibración anteriores
    _magCalibrationData.clear();
    _isMagCalibrated = false;
    _calibrationStartTime = DateTime.now();
    _magOffset = [0, 0, 0];
    _magScale = [1, 1, 1];
    _fastCalibrationMode = true; // Activar modo rápido
    _manualCalibrationMode = true; // Activar modo manual
    _needsCalibration = true;
    print("🎯 Calibración manual iniciada - Mueve el teléfono en forma de 8");
  }
  
  // Finalizar calibración manual
  void stopManualCalibration() {
    _manualCalibrationMode = false;
  }
  
  // Verificar si está en modo de calibración manual
  bool get isManualCalibrationMode => _manualCalibrationMode;
  
  // Obtener progreso de calibración (0.0 a 1.0)
  double getCalibrationProgress() {
    int samplesNeeded = _fastCalibrationMode ? _calibrationSamplesNeededFast : _calibrationSamplesNeeded;
    if (samplesNeeded == 0) return 1.0;
    double progress = (_magCalibrationData.length / samplesNeeded).clamp(0.0, 1.0);
    return progress;
  }
  
  // Verificar si la calibración está completa
  bool isCalibrationComplete() {
    return _isMagCalibrated && getCalibrationProgress() >= 1.0;
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
  double _minStepInterval = 0.15; // Segundos mínimos entre pasos (REDUCIDO para detectar más rápido)

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

    // Notificar que la posición cambió INMEDIATAMENTE
    _notify();
    
    // Notificar también después de un pequeño delay para asegurar actualización
    Future.delayed(const Duration(milliseconds: 50), () {
      _notify();
    });

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

      // Detección MÁS SENSIBLE: cuando z sube por encima de 9.8 (más bajo = más sensible)
      // Esto detecta el impacto del pie al caminar de forma más rápida
      // Usar umbral más bajo para detectar pasos más fácilmente
      double accelMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Detectar pasos usando la magnitud del acelerómetro (más preciso)
      // Detectar cuando hay un pico de aceleración (impacto del pie)
      if (accelMagnitude > 10.0 && _lastAccelZ <= 10.0) {
        _onStepDetected();
      }
      _lastAccelZ = accelMagnitude;
      
      // Notificar cambios frecuentes del acelerómetro para que el marcador se actualice en tiempo real
      _notify();
    });

    // GIROSCOPIO → detectar CUALQUIER rotación para actualizar brújula inmediatamente
    _gyroSub = gyroscopeEventStream().listen((event) {
      gyroscope = [event.x, event.y, event.z];
      
      // Calcular magnitud del giroscopio (velocidad angular)
      double gyroMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      DateTime now = DateTime.now();
      
      // Detectar CUALQUIER rotación (umbral más bajo para detectar giros más precisos)
      double rotationThreshold = 0.2; // rad/s - umbral más bajo para detectar giros más rápido
      if (gyroMagnitude > rotationThreshold) {
        // CUALQUIER rotación detectada - activar flag para actualizar brújula con mayor precisión
        _gyroRotationDetected = true;
        _lastGyroRotation = now;
        
        // Si la rotación es significativa, forzar recalibración inmediata
        if (gyroMagnitude > 0.5) {
          _needsCalibration = true;
          _fastCalibrationMode = true;
          _calibrationStartTime = now;
        }
      }
      
      // Desactivar flag después del timeout si no hay más rotación
      if (_gyroRotationDetected && now.difference(_lastGyroRotation) > _gyroRotationTimeout) {
        _gyroRotationDetected = false;
      }
      
      // Detectar giro brusco (rotación rápida del teléfono) para RECALIBRACIÓN INSTANTÁNEA
      if (gyroMagnitude > _gyroMagnitudeThreshold) {
        // Giro brusco detectado - RECALIBRACIÓN INSTANTÁNEA Y AGRESIVA
        print("🔄 Giro brusco detectado (${gyroMagnitude.toStringAsFixed(2)} rad/s) - Recalibrando INSTANTÁNEAMENTE");
        
        // Limpiar calibración anterior y forzar recalibración inmediata
        _needsCalibration = true;
        _lastCalibrationTime = DateTime(1970); // Forzar recalibración inmediata
        _isMagCalibrated = false; // Recalibrar magnetómetro también
        _magCalibrationData.clear(); // Limpiar datos antiguos
        _calibrationStartTime = now;
        _fastCalibrationMode = true; // Activar modo rápido
        
        // Acelerar recolección de muestras para recalibración rápida
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
      
      // En modo manual, recolectar muestras más agresivamente
      if (_manualCalibrationMode) {
        // En modo manual, recolectar muestras con menor umbral de variación
        // Esto captura mejor el movimiento en forma de "8"
        if (_magCalibrationData.length > _calibrationSamplesNeeded) {
          shouldCollectSample = magVariation > 1.0 || now.difference(_lastCalibrationUpdate) > Duration(milliseconds: 500);
        } else {
          // Si no tenemos suficientes muestras, recolectar más agresivamente
          shouldCollectSample = magVariation > 0.5 || now.difference(_lastCalibrationUpdate) > Duration(milliseconds: 200);
        }
      } else if (_magCalibrationData.length > _calibrationSamplesNeeded) {
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
        _lastCalibrationUpdate = now;
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
      
      // ACTUALIZACIÓN DE BRÚJULA - Filtro RÁPIDO para respuesta en tiempo real
      if (diff.abs() > 0.001) { // Umbral muy bajo para actualizaciones inmediatas
        double newHeading;
        
        // Si hay giro detectado, actualizar INMEDIATAMENTE y rápido
        if (_gyroRotationDetected) {
          // Filtro más agresivo cuando hay giro para respuesta inmediata
          double alpha = _isWalking ? 0.7 : 0.85; // MUCHO más rápido
          double change = diff * alpha;
          
          // Permitir cambios más grandes cuando hay giro
          double maxChangePerFrame = _isWalking ? 0.4 : 0.6; // Mucho más rápido
          if (change.abs() > maxChangePerFrame) {
            change = change > 0 ? maxChangePerFrame : -maxChangePerFrame;
          }
          
          newHeading = currentHeading + change;
        }
        // Si estás caminando en línea recta, permitir cambios pequeños pero rápidos
        else if (_isWalkingStraight && _isWalking) {
          // Caminando en línea recta - permitir cambios pequeños pero visibles
          newHeading = currentHeading + (diff * 0.3); // Más visible
        }
        // Si estás caminando pero no en línea recta
        else if (_isWalking) {
          // Cuando caminas, actualizar más rápido para que siga al teléfono
          double alpha = 0.6; // Mucho más rápido que antes
          double change = diff * alpha;
          double maxChangePerFrame = 0.2; // Más rápido
          if (change.abs() > maxChangePerFrame) {
            change = change > 0 ? maxChangePerFrame : -maxChangePerFrame;
          }
          newHeading = currentHeading + change;
        }
        // Cuando estás quieto, actualizar rápido para respuesta inmediata
        else {
          // Filtro más agresivo cuando estás quieto para respuesta inmediata
          double alpha = 0.75; // Mucho más rápido
          double change = diff * alpha;
          
          // Permitir cambios más grandes para respuesta rápida
          double maxChangePerFrame = 0.3; // Mucho más rápido
          if (change.abs() > maxChangePerFrame) {
            change = change > 0 ? maxChangePerFrame : -maxChangePerFrame;
          }
          
          newHeading = currentHeading + change;
        }
        
        // Normalizar heading resultante a [-π, π]
        while (newHeading > math.pi) newHeading -= 2 * math.pi;
        while (newHeading < -math.pi) newHeading += 2 * math.pi;
        
        heading = newHeading;
        _lastHeadingValue = newHeading;
        _lastUpdateTime = now;
        _lastRawHeading = rawHeading;
        _notify(); // Notificar SIEMPRE para actualizar en tiempo real
      } else {
        // Incluso si el cambio es pequeño, notificar para mantener actualizado
        _notify();
      }
      
      // Desactivar modo rápido después de un tiempo
      if (_fastCalibrationMode && now.difference(_calibrationStartTime).inSeconds > 3) {
        _fastCalibrationMode = false;
        _needsCalibration = false;
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

/// Widget que muestra el marcador del usuario en el mapa
/// Maneja el posicionamiento y movimiento del marcador
class UserLocationWidget extends StatelessWidget {
  final MapNode? entranceNode;
  final SensorService sensorService;
  final TransformationController transformationController;
  final Size screenSize;

  const UserLocationWidget({
    super.key,
    required this.entranceNode,
    required this.sensorService,
    required this.transformationController,
    required this.screenSize,
  });

  /// Transforma coordenadas SVG a coordenadas de pantalla
  Offset _transformSvgToScreen(double svgX, double svgY) {
    const double svgWidth = 2117.0;
    const double svgHeight = 1729.0;
    
    final scaleX = screenSize.width / svgWidth;
    final scaleY = screenSize.height / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    final scaledWidth = svgWidth * scale;
    final scaledHeight = svgHeight * scale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;
    
    return Offset(offsetX + svgX * scale, offsetY + svgY * scale);
  }

  /// Calcula la posición del marcador
  Offset? _getMarkerPosition() {
    if (entranceNode == null) return null;
    
    // Usar MapScaleConverter.sensorPositionToSvg para convertir correctamente
    // Este método ya maneja la conversión de metros a píxeles SVG y la inversión del eje Y
    final svgPosition = MapScaleConverter.sensorPositionToSvg(
      posX: sensorService.posX,
      posY: sensorService.posY,
      initialSvgX: entranceNode!.x,
      initialSvgY: entranceNode!.y,
    );
    
    // Transformar coordenadas SVG a coordenadas de pantalla base
    final basePoint = _transformSvgToScreen(svgPosition.dx, svgPosition.dy);
    
    // Aplicar transformación del InteractiveViewer (zoom y pan)
    final matrix = transformationController.value;
    final transformedX = matrix.getRow(0).x * basePoint.dx + 
                        matrix.getRow(0).y * basePoint.dy + 
                        matrix.getRow(0).w;
    final transformedY = matrix.getRow(1).x * basePoint.dx + 
                        matrix.getRow(1).y * basePoint.dy + 
                        matrix.getRow(1).w;
    
    return Offset(transformedX, transformedY);
  }

  @override
  Widget build(BuildContext context) {
    final position = _getMarkerPosition();
    if (position == null) return const SizedBox.shrink();
    
    return Positioned(
      left: position.dx - 18,
      top: position.dy - 18,
      child: _GoogleMapsMarker(
        heading: sensorService.heading,
        onTap: () => _showMarkerOptions(context),
      ),
    );
  }
  
  /// Muestra el diálogo de opciones del marcador (estilo Google Maps)
  void _showMarkerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MarkerOptionsSheet(
        sensorService: sensorService,
      ),
    );
  }
}

/// Widget que representa el marcador del usuario estilo Google Maps
/// Punto azul sólido con cono direccional semi-transparente
class _GoogleMapsMarker extends StatelessWidget {
  final double heading; // Heading en radianes
  final VoidCallback? onTap; // Callback cuando se toca el marcador
  
  const _GoogleMapsMarker({
    required this.heading,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: const Size(36, 36),
        painter: _GoogleMapsMarkerPainter(heading: heading),
      ),
    );
  }
}

/// CustomPainter para dibujar el marcador estilo Google Maps
/// Punto azul sólido con cono direccional semi-transparente
class _GoogleMapsMarkerPainter extends CustomPainter {
  final double heading; // Heading en radianes
  
  _GoogleMapsMarkerPainter({required this.heading});
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Radio del círculo azul (punto central)
    final circleRadius = 8.0;
    
    // Dibujar el cono direccional primero (detrás del círculo)
    final conePaint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    
    // Ángulo de apertura del cono
    final coneAngle = math.pi / 1.8; // ~100 grados
    final coneLength = 24.0;
    
    // Calcular los bordes del cono basándose en el heading
    final adjustedHeading = heading - math.pi / 2;
    final startAngle = adjustedHeading - coneAngle / 2;
    
    // Dibujar el cono como un sector circular
    final conePath = Path();
    conePath.moveTo(centerX, centerY);
    
    const numPoints = 30;
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final currentAngle = startAngle + (coneAngle * t);
      
      final pointX = centerX + math.cos(currentAngle) * coneLength;
      final pointY = centerY + math.sin(currentAngle) * coneLength;
      
      if (i == 0) {
        conePath.lineTo(pointX, pointY);
      } else {
        conePath.lineTo(pointX, pointY);
      }
    }
    
    conePath.close();
    canvas.drawPath(conePath, conePaint);
    
    // Dibujar el círculo azul sólido (encima del cono)
    final circlePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final circleBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    canvas.drawCircle(Offset(centerX, centerY), circleRadius, circlePaint);
    canvas.drawCircle(Offset(centerX, centerY), circleRadius, circleBorderPaint);
  }
  
  @override
  bool shouldRepaint(_GoogleMapsMarkerPainter oldDelegate) {
    return (heading - oldDelegate.heading).abs() > 0.01;
  }
}

/// Diálogo de opciones del marcador (estilo Google Maps)
class _MarkerOptionsSheet extends StatelessWidget {
  final SensorService sensorService;
  
  const _MarkerOptionsSheet({
    required this.sensorService,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF4285F4),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu ubicación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Calibra la brújula para mejorar la precisión',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Opción de calibrar
            ListTile(
              leading: const Icon(Icons.explore, color: Color(0xFF4285F4)),
              title: const Text('Calibrar brújula'),
              subtitle: const Text('Mueve el teléfono en forma de 8'),
              onTap: () {
                Navigator.pop(context);
                _showCalibrationDialog(context, sensorService);
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  /// Muestra el diálogo de calibración con instrucciones visuales
  void _showCalibrationDialog(BuildContext context, SensorService sensorService) {
    sensorService.startManualCalibration();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CalibrationDialog(sensorService: sensorService),
    );
  }
}

/// Diálogo de calibración con instrucciones visuales (estilo Google Maps)
class _CalibrationDialog extends StatefulWidget {
  final SensorService sensorService;
  
  const _CalibrationDialog({
    required this.sensorService,
  });
  
  @override
  State<_CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<_CalibrationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _progressTimer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    
    // Actualizar progreso cada 100ms
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {});
        if (widget.sensorService.isCalibrationComplete()) {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
              _showCalibrationComplete(context);
            }
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    // Finalizar calibración manual al cerrar el diálogo
    widget.sensorService.stopManualCalibration();
    super.dispose();
  }
  
  void _showCalibrationComplete(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Calibración completada'),
          ],
        ),
        backgroundColor: Color(0xFF4285F4),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = widget.sensorService.getCalibrationProgress();
    final isComplete = widget.sensorService.isCalibrationComplete();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado de movimiento en forma de 8
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _EightShapePainter(progress: _animation.value),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título
            Text(
              isComplete ? 'Calibración completada' : 'Calibrando brújula',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Instrucciones
            Text(
              isComplete 
                ? 'La brújula está calibrada correctamente'
                : 'Mueve el teléfono lentamente\nen forma de 8 horizontal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : const Color(0xFF4285F4),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Porcentaje
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botón de cancelar
            if (!isComplete)
              TextButton(
                onPressed: () {
                  _progressTimer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter para dibujar la forma de 8 animada
class _EightShapePainter extends CustomPainter {
  final double progress; // 0 a 2π
  
  _EightShapePainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.15;
    
    final paint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Dibujar la forma de 8
    final path = Path();
    
    // Círculo superior
    final topCircle = Offset(centerX, centerY - radius * 0.8);
    path.addArc(
      Rect.fromCircle(center: topCircle, radius: radius),
      math.pi,
      math.pi * 2,
    );
    
    // Círculo inferior
    final bottomCircle = Offset(centerX, centerY + radius * 0.8);
    path.addArc(
      Rect.fromCircle(center: bottomCircle, radius: radius),
      0,
      math.pi * 2,
    );
    
    canvas.drawPath(path, paint);
    
    // Dibujar el punto que sigue la forma de 8
    final t = progress / (2 * math.pi);
    double x, y;
    
    if (t < 0.5) {
      // Primera mitad: círculo superior
      final angle = math.pi + (t * 2) * math.pi * 2;
      x = topCircle.dx + math.cos(angle) * radius;
      y = topCircle.dy + math.sin(angle) * radius;
    } else {
      // Segunda mitad: círculo inferior
      final angle = ((t - 0.5) * 2) * math.pi * 2;
      x = bottomCircle.dx + math.cos(angle) * radius;
      y = bottomCircle.dy + math.sin(angle) * radius;
    }
    
    final dotPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, y), 8, dotPaint);
  }
  
  @override
  bool shouldRepaint(_EightShapePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
