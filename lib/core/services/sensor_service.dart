//Version final (por el momento)
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
  
  List<double> _smoothedAccel = [0, 0, 9.8];
  double _accelSmoothing = 0.95;
  
  double _stablePitch = 0;
  double _stableRoll = 0;
  List<double> _pitchHistory = [];
  List<double> _rollHistory = [];
  
  DateTime _lastGyroUpdate = DateTime.now();
  double _gyroMagnitudeThreshold = 2.0;
  bool _gyroRotationDetected = false;
  DateTime _lastGyroRotation = DateTime.now();
  static const Duration _gyroRotationTimeout = Duration(milliseconds: 300);
  
  List<List<double>> _continuousCalibrationData = [];
  List<double> _magOffset = [0, 0, 0];
  List<double> _magScale = [1, 1, 1];
  bool _isMagCalibrated = false;
  DateTime _lastContinuousCalibration = DateTime.now();
  static const Duration _continuousCalibrationInterval = Duration(seconds: 1);
  
  double? _latitude;
  double? _longitude;
  double _magneticDeclination = 0.0;
  DateTime _lastLocationUpdate = DateTime(1970);
  static const Duration _locationUpdateInterval = Duration(minutes: 5);
  DateTime _calibrationStartTime = DateTime.now();
  static const int _calibrationSamplesNeeded = 100;
  static const int _calibrationSamplesNeededFast = 50;
  static const int _maxCalibrationSamples = 300;
  DateTime _lastCalibrationUpdate = DateTime.now();
  static const Duration _calibrationUpdateInterval = Duration(seconds: 3);
  static const Duration _calibrationUpdateIntervalFast = Duration(milliseconds: 300);
  bool _fastCalibrationMode = false;
  
  // Calibración continua del magnetómetro
  void _calibrateContinuousMagnetometer() {
    if (_continuousCalibrationData.length < _calibrationSamplesNeeded) return;
    
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    double minZ = double.infinity, maxZ = -double.infinity;
    
    for (var sample in _continuousCalibrationData) {
      if (sample[0] < minX) minX = sample[0];
      if (sample[0] > maxX) maxX = sample[0];
      if (sample[1] < minY) minY = sample[1];
      if (sample[1] > maxY) maxY = sample[1];
      if (sample[2] < minZ) minZ = sample[2];
      if (sample[2] > maxZ) maxZ = sample[2];
    }
    
    double newOffsetX = (minX + maxX) / 2;
    double newOffsetY = (minY + maxY) / 2;
    double newOffsetZ = (minZ + maxZ) / 2;
    
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
    
    double smoothingFactor = _isMagCalibrated ? 0.5 : 0.0;
    
    _magOffset[0] = smoothingFactor * _magOffset[0] + (1 - smoothingFactor) * newOffsetX;
    _magOffset[1] = smoothingFactor * _magOffset[1] + (1 - smoothingFactor) * newOffsetY;
    _magOffset[2] = smoothingFactor * _magOffset[2] + (1 - smoothingFactor) * newOffsetZ;
    
    _magScale[0] = smoothingFactor * _magScale[0] + (1 - smoothingFactor) * newScaleX;
    _magScale[1] = smoothingFactor * _magScale[1] + (1 - smoothingFactor) * newScaleY;
    _magScale[2] = smoothingFactor * _magScale[2] + (1 - smoothingFactor) * newScaleZ;
    
    _isMagCalibrated = true;
  }
  
  // Recalibración automática del magnetómetro
  void _calibrateAutoRecalibration() {
    if (_autoRecalibrationData.length < _autoRecalibrationSamplesNeeded) return;
    
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    double minZ = double.infinity, maxZ = -double.infinity;
    
    for (var sample in _autoRecalibrationData) {
      if (sample[0] < minX) minX = sample[0];
      if (sample[0] > maxX) maxX = sample[0];
      if (sample[1] < minY) minY = sample[1];
      if (sample[1] > maxY) maxY = sample[1];
      if (sample[2] < minZ) minZ = sample[2];
      if (sample[2] > maxZ) maxZ = sample[2];
    }
    
    double newOffsetX = (minX + maxX) / 2;
    double newOffsetY = (minY + maxY) / 2;
    double newOffsetZ = (minZ + maxZ) / 2;
    
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
    
    _magOffset[0] = newOffsetX;
    _magOffset[1] = newOffsetY;
    _magOffset[2] = newOffsetZ;
    
    _magScale[0] = newScaleX;
    _magScale[1] = newScaleY;
    _magScale[2] = newScaleZ;
    
    _isMagCalibrated = true;
    _autoRecalibrationActive = false;
    print("✅ Sistema 2: Recalibración AUTOMÁTICA completada (Sistema 1 corregido)");
  }

  double heading = 0;
  double _lastRawHeading = 0;
  DateTime _lastUpdateTime = DateTime.now();
  double _lastHeadingValue = 0;
  
  DateTime _lastCalibrationTime = DateTime.now();
  bool _needsCalibration = false;
  bool _autoRecalibrationActive = false;
  List<List<double>> _autoRecalibrationData = [];
  static const int _autoRecalibrationSamplesNeeded = 120;
  
  List<Map<String, dynamic>> _detectedRotations = [];
  static const int _maxRotationHistory = 100;
  DateTime _lastHeadingChangeRecord = DateTime.now();
  static const Duration _headingChangeRecordInterval = Duration(milliseconds: 100);
  double _lastRecordedHeading = 0.0;
  static const double _minHeadingChangeToRecord = 0.05;
  
  double _lastGyroMagnitude = 0.0;
  DateTime _lastRotationRecord = DateTime.now();
  static const Duration _rotationRecordInterval = Duration(milliseconds: 200);
  static const double _minRotationThreshold = 0.15;
  static const double _smoothRotationThreshold = 0.2;
  
  DateTime _lastStepDetected = DateTime.now();
  bool _isWalking = false;
  
  bool _isWalkingStraight = false;

  double posX = 0;
  double posY = 0;
  double stepLength = 0.6;

  Function()? onDataChanged;
  
  // Activar recalibración automática
  void _activateAutoRecalibration() {
    if (!_autoRecalibrationActive) {
      _autoRecalibrationActive = true;
      _needsCalibration = true;
      _lastCalibrationTime = DateTime.now();
      _autoRecalibrationData.clear();
      _calibrationStartTime = DateTime.now();
      _fastCalibrationMode = false;
      print("🔄 Sistema 2: Recalibración AUTOMÁTICA activada (corrigiendo Sistema 1)");
    }
  }
  
  // Progreso de recalibración automática
  double getAutoRecalibrationProgress() {
    if (!_autoRecalibrationActive) return 0.0;
    return math.min(1.0, _autoRecalibrationData.length / _autoRecalibrationSamplesNeeded);
  }
  
  // Verificar recalibración automática completa
  bool isAutoRecalibrationComplete() {
    return _autoRecalibrationActive && _autoRecalibrationData.length >= _autoRecalibrationSamplesNeeded;
  }
  
  // Recalibrar manualmente
  void recalibrate() {
    _activateAutoRecalibration();
  }
  
  // Estado de calibración
  Map<String, dynamic> getCalibrationStatus() {
    int continuousSamples = _continuousCalibrationData.length;
    double continuousProgress = continuousSamples >= _calibrationSamplesNeeded ? 1.0 : continuousSamples / _calibrationSamplesNeeded;
    
    return {
      'continuousCalibration': {
        'isActive': true,
        'isCalibrated': _isMagCalibrated,
        'progress': continuousProgress,
        'samplesCollected': continuousSamples,
        'samplesNeeded': _calibrationSamplesNeeded,
      },
      'autoRecalibration': {
        'isActive': _autoRecalibrationActive,
        'progress': getAutoRecalibrationProgress(),
        'isComplete': isAutoRecalibrationComplete(),
        'samplesCollected': _autoRecalibrationData.length,
        'samplesNeeded': _autoRecalibrationSamplesNeeded,
      },
      'hasLocation': _latitude != null && _longitude != null,
      'latitude': _latitude,
      'longitude': _longitude,
      'magneticDeclination': _magneticDeclination * 180 / math.pi,
      'rotationsDetected': _detectedRotations.length,
      'lastRotationTime': _detectedRotations.isNotEmpty ? _detectedRotations.last['timestamp'] : null,
    };
  }
  
  // Historial de giros
  List<Map<String, dynamic>> getRotationHistory() {
    return List.from(_detectedRotations);
  }
  
  // Actualizar ubicación
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
  
  // Calcular declinación magnética
  double _calculateMagneticDeclination(double lat, double lon) {
    double latRad = lat * math.pi / 180.0;
    double lonRad = lon * math.pi / 180.0;
    
    int year = DateTime.now().year;
    double yearFraction = (year - 2020) / 100.0;
    
    double declination = 0.0;
    
    if (lat < 0) {
      declination = -0.028 + (lat * 0.0004) + (lon * 0.00025);
      
      if (lon < 0) {
        declination += (lon * 0.0002);
        declination += math.sin(lonRad) * 0.005;
      }
      
      declination += (lat * lat * 0.000002);
      declination += (lon * lon * 0.0000015);
      declination += (lat * lon * 0.0000005);
      declination += yearFraction * 0.0017;
    } else {
      declination = 0.02 + (lat * 0.00025) + (lon * 0.00015);
      declination += (lat * lat * 0.0000015);
      declination += (lon * lon * 0.000001);
      declination += (lat * lon * 0.0000003);
      declination += yearFraction * 0.0017;
    }
    
    double magneticLat = lat + (lon * 0.12);
    declination += math.sin(magneticLat * math.pi / 180.0) * 0.012;
    declination += math.cos(magneticLat * math.pi / 180.0) * 0.003;
    
    while (declination > math.pi) declination -= 2 * math.pi;
    while (declination < -math.pi) declination += 2 * math.pi;
    
    return declination;
  }

  DateTime _lastStepTime = DateTime.now();
  double _lastAccelZ = 9.8;
  double _lastAccelMagnitude = 9.8;
  List<double> _accelMagnitudeHistory = [];
  static const int _accelHistorySize = 10;
  double _minStepInterval = 0.3;
  double _minStepIntervalRunning = 0.15;
  bool _isRunning = false;
  
  // Detectar tipo de movimiento
  void _updateMovementType() {
    if (_accelMagnitudeHistory.length < 5) return;
    
    double avgInterval = 0.0;
    for (int i = 1; i < _accelMagnitudeHistory.length; i++) {
      avgInterval += _accelMagnitudeHistory[i];
    }
    avgInterval /= (_accelMagnitudeHistory.length - 1);
    
    _isRunning = avgInterval > 12.0;
    
    if (_isRunning) {
      stepLength = 1.2;
    } else {
      stepLength = 0.6;
    }
  }

  // Detectar paso
  void _onStepDetected(double accelMagnitude) {
    DateTime now = DateTime.now();
    
    double minInterval = _isRunning ? _minStepIntervalRunning : _minStepInterval;
    
    if (now.difference(_lastStepTime).inMilliseconds < (minInterval * 1000)) {
      return;
    }

    _lastStepTime = now;
    _lastStepDetected = now;
    _isWalking = true;
    
    _accelMagnitudeHistory.add(accelMagnitude);
    if (_accelMagnitudeHistory.length > _accelHistorySize) {
      _accelMagnitudeHistory.removeAt(0);
    }
    _updateMovementType();

    double correctedHeading = heading;
    if (_latitude != null && _longitude != null) {
      double latLonCorrection = (_latitude! * 0.00001) + (_longitude! * 0.000008);
      correctedHeading = heading + latLonCorrection;
      
      while (correctedHeading > math.pi) correctedHeading -= 2 * math.pi;
      while (correctedHeading < -math.pi) correctedHeading += 2 * math.pi;
    }
    
    double moveX = stepLength * math.sin(correctedHeading);
    double moveY = -stepLength * math.cos(correctedHeading);

    posX = posX + moveX;
    posY = posY + moveY;

    _notify();

    String movementType = _isRunning ? "🏃 CORRIENDO" : "🚶 CAMINANDO";
    print("$movementType → x:${posX.toStringAsFixed(2)}  y:${posY.toStringAsFixed(2)}  heading:${(heading * 180 / math.pi).toStringAsFixed(1)}°  paso:${stepLength.toStringAsFixed(2)}m");
  }

  // Iniciar sensores
  void start() {
    _lastStepTime = DateTime.now();
    _lastAccelZ = 9.8;
    _lastAccelMagnitude = 9.8;
    _accelMagnitudeHistory.clear();
    _isRunning = false;
    _lastStepDetected = DateTime(1970);
    _isWalking = false;
    posX = 0;
    posY = 0;
    stepLength = 0.6;
    
    _continuousCalibrationData.clear();
    _isMagCalibrated = false;
    _calibrationStartTime = DateTime.now();
    _magOffset = [0, 0, 0];
    _magScale = [1, 1, 1];
    
    updateLocation();

    _accelSub = accelerometerEventStream().listen((event) {
      accelerometer = [event.x, event.y, event.z];
      
      _smoothedAccel[0] = _accelSmoothing * _smoothedAccel[0] + (1 - _accelSmoothing) * event.x;
      _smoothedAccel[1] = _accelSmoothing * _smoothedAccel[1] + (1 - _accelSmoothing) * event.y;
      _smoothedAccel[2] = _accelSmoothing * _smoothedAccel[2] + (1 - _accelSmoothing) * event.z;

      double accelMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      double walkingThreshold = 10.5;
      
      bool stepDetected = false;
      if (_lastAccelZ <= walkingThreshold && event.z > walkingThreshold) {
        stepDetected = true;
      }
      
      _lastAccelZ = event.z;
      _lastAccelMagnitude = accelMagnitude;
      
      if (stepDetected) {
        _onStepDetected(accelMagnitude);
      }
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      gyroscope = [event.x, event.y, event.z];
      
      double gyroMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      DateTime now = DateTime.now();
      
      double rotationThreshold = _smoothRotationThreshold;
      
      if (gyroMagnitude > rotationThreshold) {
        _gyroRotationDetected = true;
        _lastGyroRotation = now;
      }
      
      if (_gyroRotationDetected && now.difference(_lastGyroRotation) > _gyroRotationTimeout) {
        _gyroRotationDetected = false;
      }
      
      if (gyroMagnitude > _minRotationThreshold && 
          now.difference(_lastRotationRecord) > _rotationRecordInterval) {
        
        _detectedRotations.add({
          'timestamp': now,
          'gyroMagnitude': gyroMagnitude,
          'heading': heading,
          'headingDegrees': heading * 180 / math.pi,
          'isBrisk': gyroMagnitude > _gyroMagnitudeThreshold,
        });
        
        _lastRotationRecord = now;
        _lastGyroMagnitude = gyroMagnitude;
        
        if (_detectedRotations.length > _maxRotationHistory) {
          _detectedRotations.removeAt(0);
        }
      }
      
      if (gyroMagnitude > _gyroMagnitudeThreshold) {
        print("🔄 Giro brusco detectado (${gyroMagnitude.toStringAsFixed(2)} rad/s) - Recalibrando INSTANTÁNEAMENTE");
        
        _needsCalibration = true;
        _lastCalibrationTime = DateTime(1970);
        _isMagCalibrated = false;
        
        if (_continuousCalibrationData.length > _calibrationSamplesNeededFast) {
          _continuousCalibrationData = _continuousCalibrationData.sublist(_continuousCalibrationData.length - _calibrationSamplesNeededFast);
        } else {
          _continuousCalibrationData.clear();
        }
        
        _calibrationStartTime = now;
        _fastCalibrationMode = true;
        
        _notify();
      }
      
      _lastGyroUpdate = now;
    });

    _magnetSub = magnetometerEventStream().listen((event) {
      magnetometer = [event.x, event.y, event.z];

      double ax = _smoothedAccel[0];
      double ay = _smoothedAccel[1];
      double az = _smoothedAccel[2];
      double accNorm = math.sqrt(ax * ax + ay * ay + az * az);
      if (accNorm == 0) return;

      ax /= accNorm;
      ay /= accNorm;
      az /= accNorm;

      double pitch = math.asin(-ax);
      double roll = math.atan2(ay, az);
      
      if (_isWalking) {
        if (_pitchHistory.isNotEmpty && _rollHistory.isNotEmpty) {
          pitch = _stablePitch;
          roll = _stableRoll;
        }
      } else {
        _pitchHistory.add(pitch);
        _rollHistory.add(roll);
        if (_pitchHistory.length > 30) _pitchHistory.removeAt(0);
        if (_rollHistory.length > 30) _rollHistory.removeAt(0);
        
        if (_pitchHistory.length >= 10) {
          _stablePitch = _pitchHistory.reduce((a, b) => a + b) / _pitchHistory.length;
          _stableRoll = _rollHistory.reduce((a, b) => a + b) / _rollHistory.length;
        }
      }

      DateTime now = DateTime.now();
      
      double magVariation = math.sqrt(
        math.pow(magnetometer[0] - (_continuousCalibrationData.isNotEmpty ? _continuousCalibrationData.last[0] : magnetometer[0]), 2) +
        math.pow(magnetometer[1] - (_continuousCalibrationData.isNotEmpty ? _continuousCalibrationData.last[1] : magnetometer[1]), 2) +
        math.pow(magnetometer[2] - (_continuousCalibrationData.isNotEmpty ? _continuousCalibrationData.last[2] : magnetometer[2]), 2)
      );
      
      bool shouldCollectContinuous = true;
      if (_continuousCalibrationData.length > _calibrationSamplesNeeded) {
        shouldCollectContinuous = magVariation > 1.5 || now.difference(_lastContinuousCalibration) > Duration(milliseconds: 500);
      }
      
      if (shouldCollectContinuous) {
        _continuousCalibrationData.add([magnetometer[0], magnetometer[1], magnetometer[2]]);
        if (_continuousCalibrationData.length > _maxCalibrationSamples) {
          _continuousCalibrationData.removeAt(0);
        }
      }
      
      if (_continuousCalibrationData.length >= _calibrationSamplesNeeded && 
          now.difference(_lastContinuousCalibration) > _continuousCalibrationInterval) {
        _calibrateContinuousMagnetometer();
        _lastContinuousCalibration = now;
      }
      
      if (_autoRecalibrationActive) {
        _autoRecalibrationData.add([magnetometer[0], magnetometer[1], magnetometer[2]]);
        if (_autoRecalibrationData.length > _maxCalibrationSamples) {
          _autoRecalibrationData.removeAt(0);
        }
        
        if (_autoRecalibrationData.length >= _autoRecalibrationSamplesNeeded) {
          _calibrateAutoRecalibration();
        }
      }
      
      if (_needsCalibration && _fastCalibrationMode) {
        if (_continuousCalibrationData.length >= _calibrationSamplesNeededFast) {
          _calibrateContinuousMagnetometer();
        _lastCalibrationUpdate = now;
        }
        
        if (now.difference(_calibrationStartTime).inSeconds > 3) {
          _fastCalibrationMode = false;
          _needsCalibration = false;
        }
      }
      
      double mx = magnetometer[0];
      double my = magnetometer[1];
      double mz = magnetometer[2];
      
      if (_isMagCalibrated) {
        mx = (mx - _magOffset[0]) * _magScale[0];
        my = (my - _magOffset[1]) * _magScale[1];
        mz = (mz - _magOffset[2]) * _magScale[2];
      }
      
      double magNorm = math.sqrt(mx * mx + my * my + mz * mz);
      if (magNorm < 10) return;

      mx /= magNorm;
      my /= magNorm;
      mz /= magNorm;

      double mx2 = mx * math.cos(pitch) + mz * math.sin(pitch);
      double my2 = mx * math.sin(roll) * math.sin(pitch) + 
                   my * math.cos(roll) - 
                   mz * math.sin(roll) * math.cos(pitch);

      double rawHeading = math.atan2(my2, mx2);
      
      rawHeading = rawHeading + math.pi;
      
      if (_latitude == null || _longitude == null || 
          DateTime.now().difference(_lastLocationUpdate) > _locationUpdateInterval) {
        updateLocation();
      }
      
      if (_latitude != null && _longitude != null) {
        rawHeading = rawHeading - _magneticDeclination;
      } else {
        rawHeading = rawHeading - 0.025;
      }
      
      while (rawHeading > math.pi) rawHeading -= 2 * math.pi;
      while (rawHeading < -math.pi) rawHeading += 2 * math.pi;
      
      double currentHeading = heading;
      while (currentHeading > math.pi) currentHeading -= 2 * math.pi;
      while (currentHeading < -math.pi) currentHeading += 2 * math.pi;
      
      double diff = rawHeading - currentHeading;
      
      if (diff > math.pi) {
        diff -= 2 * math.pi;
      } else if (diff < -math.pi) {
        diff += 2 * math.pi;
      }

      double maxAllowedDiff = 1.8;
      if (diff.abs() > maxAllowedDiff) {
        return;
      }

      _isWalking = now.difference(_lastStepDetected).inSeconds < 2 && _lastStepDetected != DateTime(1970);
      
      if (_isWalking && !_gyroRotationDetected) {
        _isWalkingStraight = diff.abs() < 0.1;
      } else {
        _isWalkingStraight = false;
      }
      
      if (diff.abs() > 0.01) {
        double newHeading;
        
        if (_isWalking) {
          if (_isWalkingStraight) {
            double filterStrength = 0.15;
            double desiredChange = filterStrength * diff;
            double maxChangePerFrame = 0.05;
            if (desiredChange.abs() > maxChangePerFrame) {
              desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
            }
            newHeading = currentHeading + desiredChange;
          } else {
            if (diff.abs() > 0.2) {
              double filterStrength = 0.5;
              double desiredChange = filterStrength * diff;
              double maxChangePerFrame = 0.15;
              if (desiredChange.abs() > maxChangePerFrame) {
                desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
              }
              newHeading = currentHeading + desiredChange;
            } else {
              newHeading = currentHeading + (diff * 0.2);
            }
          }
        } else {
          if (_gyroRotationDetected) {
            double filterStrength = 0.5;
            double desiredChange = filterStrength * diff;
            double maxChangePerFrame = 0.1;
            if (desiredChange.abs() > maxChangePerFrame) {
              desiredChange = desiredChange > 0 ? maxChangePerFrame : -maxChangePerFrame;
            }
            newHeading = currentHeading + desiredChange;
          } else {
            newHeading = currentHeading;
          }
        }
        
        while (newHeading > math.pi) newHeading -= 2 * math.pi;
        while (newHeading < -math.pi) newHeading += 2 * math.pi;
        
        heading = newHeading;
        _lastHeadingValue = newHeading;
        _lastUpdateTime = now;
        _lastRawHeading = rawHeading;
        
        double headingChange = (newHeading - _lastRecordedHeading).abs();
        if (headingChange > math.pi) headingChange = 2 * math.pi - headingChange;
        
        if (headingChange > _minHeadingChangeToRecord && 
            now.difference(_lastHeadingChangeRecord) > _headingChangeRecordInterval) {
          
          _detectedRotations.add({
            'timestamp': now,
            'heading': newHeading,
            'headingDegrees': newHeading * 180 / math.pi,
            'headingChange': headingChange * 180 / math.pi,
            'rawHeading': rawHeading,
            'isFromMovement': true,
            'gyroMagnitude': _lastGyroMagnitude,
          });
          
          _lastRecordedHeading = newHeading;
          _lastHeadingChangeRecord = now;
          
          if (_detectedRotations.length > _maxRotationHistory) {
            _detectedRotations.removeAt(0);
          }
        }
        
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


