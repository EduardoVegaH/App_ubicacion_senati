import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
// import 'package:flutter_barometer/flutter_barometer.dart'; // Paquete incompatible con Android Gradle moderno

class SensorService {
  // Controladores de streams
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magnetSub;
  StreamSubscription? _baroSub;

  //Ultimos valores capturados
  List<double> accelerometer = [0, 0, 0];
  List<double> gyroscope = [0, 0, 0];
  List<double> magnetometer = [0, 0, 0];
  double barometer = 0;

  double posX = 0;
  double posY = 0;
  double heading = 0;

  double stepLength = 0.6; // Longitud promedio de paso en metros

  Function()? onDataChanged;
  
  // Timer para imprimir valores periódicamente
  // Timer? _printTimer;
  void _onStepDetected(){
    posX += stepLength * math.cos(heading);
    posY += stepLength * math.sin(heading);

    print("Paso detectado -> x: $posX , y: $posY , heading: $heading");
  }

  void start() {
    // Iniciar timer para imprimir valores cada segundo
    // _printTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    //   _printSensorValues();
    // });
    
    //Acelerómetro
    _accelSub = accelerometerEventStream().listen((event) {
      accelerometer = [event.x, event.y, event.z];

      //Detectar paso con un pico de aceleracion
      if(event.z > 12 ){
        _onStepDetected();
      }
      _notify();
    });

    //Giroscopio
    _gyroSub = gyroscopeEventStream().listen((event) {
      gyroscope = [event.x, event.y, event.z];

      //Sumar la rotacion al heading
      heading += event.z * 0.02; // factor de ajuste
      _notify();
    });

    //Magnetómetro (brújula)
    _magnetSub = magnetometerEventStream().listen((event) {
      magnetometer = [event.x, event.y, event.z];
      _notify();
    });

    //Barometro (presión atmosferica)
    // NOTA: flutter_barometer 0.1.0 es incompatible con Android Gradle moderno
    // El barómetro se mantiene en 0 hasta encontrar una alternativa compatible
    // TODO: Buscar una librería alternativa para barómetro o implementar nativo
  }
  
  // void _printSensorValues() {
  //   print('ACC: ${accelerometer.toString()}');
  //   print('GYRO: ${gyroscope.toString()}');
  //   print('MAGNET: ${magnetometer.toString()}');
  //   print('BARO: ${barometer.toStringAsFixed(2)}');
  //   print('---------------------------');
  // }

  void _notify() {
    if (onDataChanged != null) {
      onDataChanged!();
    }
  }

  void stop() {
    // _printTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magnetSub?.cancel();
    _baroSub?.cancel();
  }
}
