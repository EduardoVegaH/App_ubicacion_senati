import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/map_node.dart';

/// Utilidad para convertir entre coordenadas del SVG (píxeles) y coordenadas reales (metros)
/// 
/// Basado en las mediciones reales del campus SENATI:
/// - Las imágenes muestran mediciones de 62.65m y 36.00m
/// - El SVG tiene dimensiones de 2117x1729 píxeles
/// 
/// Para calcular la escala precisa, necesitas:
/// 1. Identificar dos puntos conocidos en el SVG (coordenadas x, y)
/// 2. Medir la distancia real entre esos puntos en metros
/// 3. Calcular: escala = distancia_metros / distancia_pixeles
class MapScaleConverter {
  /// Dimensiones del SVG en píxeles
  static const double svgWidth = 2117.0;
  static const double svgHeight = 1729.0;
  
  /// ESCALA APROXIMADA (necesita calibración con puntos de referencia reales)
  /// 
  /// Basado en estimaciones:
  /// - Si el campus mide aproximadamente 200m x 150m (estimación)
  /// - Y el SVG mide 2117px x 1729px
  /// - Escala aproximada: ~0.095 metros por píxel
  /// 
  /// ⚠️ ESTA ESCALA ES APROXIMADA - DEBE SER CALIBRADA CON MEDICIONES REALES
  static const double _estimatedMetersPerPixel = 0.095; // metros por píxel
  
  /// Puntos de referencia conocidos para calibración precisa
  /// Formato: {puntoId: {svgX, svgY, realX, realY}}
  /// Donde realX y realY están en metros desde un punto de origen
  static final Map<String, Map<String, double>> _referencePoints = {};
  
  /// Escala calibrada (metros por píxel)
  /// Se calcula automáticamente cuando se agregan puntos de referencia
  static double _calibratedMetersPerPixel = _estimatedMetersPerPixel;
  
  /// Agregar un punto de referencia conocido para calibrar la escala
  /// 
  /// [pointId] - Identificador único del punto
  /// [svgX, svgY] - Coordenadas en el SVG (píxeles)
  /// [realX, realY] - Coordenadas reales en metros desde un punto de origen
  static void addReferencePoint({
    required String pointId,
    required double svgX,
    required double svgY,
    required double realX,
    required double realY,
  }) {
    _referencePoints[pointId] = {
      'svgX': svgX,
      'svgY': svgY,
      'realX': realX,
      'realY': realY,
    };
    
    // Recalcular escala si hay al menos 2 puntos
    if (_referencePoints.length >= 2) {
      _recalibrateScale();
    }
  }
  
  /// Recalcular la escala basándose en los puntos de referencia
  static void _recalibrateScale() {
    if (_referencePoints.length < 2) return;
    
    final points = _referencePoints.values.toList();
    double totalScale = 0.0;
    int count = 0;
    
    // Calcular escala entre todos los pares de puntos
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final p1 = points[i];
        final p2 = points[j];
        
        // Distancia en píxeles
        final dxPx = p1['svgX']! - p2['svgX']!;
        final dyPx = p1['svgY']! - p2['svgY']!;
        final distPx = math.sqrt(dxPx * dxPx + dyPx * dyPx);
        
        // Distancia en metros
        final dxM = p1['realX']! - p2['realX']!;
        final dyM = p1['realY']! - p2['realY']!;
        final distM = math.sqrt(dxM * dxM + dyM * dyM);
        
        if (distPx > 0) {
          final scale = distM / distPx;
          totalScale += scale;
          count++;
        }
      }
    }
    
    if (count > 0) {
      _calibratedMetersPerPixel = totalScale / count;
      print('✅ Escala recalibrada: ${_calibratedMetersPerPixel.toStringAsFixed(6)} m/px (basado en $count mediciones)');
    }
  }
  
  /// Obtener la escala actual (metros por píxel)
  static double getMetersPerPixel() => _calibratedMetersPerPixel;
  
  /// Obtener la escala actual (píxeles por metro)
  static double getPixelsPerMeter() => 1.0 / _calibratedMetersPerPixel;
  
  /// Convertir distancia en píxeles a metros
  static double pixelsToMeters(double pixels) {
    return pixels * _calibratedMetersPerPixel;
  }
  
  /// Convertir distancia en metros a píxeles
  static double metersToPixels(double meters) {
    return meters / _calibratedMetersPerPixel;
  }
  
  /// Convertir coordenadas SVG (píxeles) a coordenadas reales (metros)
  /// 
  /// [svgX, svgY] - Coordenadas en el SVG
  /// [originSvgX, originSvgY] - Punto de origen en el SVG (opcional, por defecto 0,0)
  /// 
  /// Retorna: Offset(realX, realY) en metros desde el origen
  static Offset svgToRealCoordinates({
    required double svgX,
    required double svgY,
    double originSvgX = 0.0,
    double originSvgY = 0.0,
  }) {
    final dx = (svgX - originSvgX) * _calibratedMetersPerPixel;
    final dy = (svgY - originSvgY) * _calibratedMetersPerPixel;
    return Offset(dx, dy);
  }
  
  /// Convertir coordenadas reales (metros) a coordenadas SVG (píxeles)
  /// 
  /// [realX, realY] - Coordenadas reales en metros desde el origen
  /// [originSvgX, originSvgY] - Punto de origen en el SVG (opcional, por defecto 0,0)
  /// 
  /// Retorna: Offset(svgX, svgY) en píxeles del SVG
  static Offset realToSvgCoordinates({
    required double realX,
    required double realY,
    double originSvgX = 0.0,
    double originSvgY = 0.0,
  }) {
    final dx = realX / _calibratedMetersPerPixel;
    final dy = realY / _calibratedMetersPerPixel;
    return Offset(originSvgX + dx, originSvgY + dy);
  }
  
  /// Convertir posición relativa del SensorService (posX, posY en metros) a coordenadas SVG
  /// 
  /// [posX, posY] - Posición relativa en metros desde el punto inicial
  /// [initialSvgX, initialSvgY] - Coordenadas SVG del punto inicial (ej: nodo de entrada)
  /// 
  /// Retorna: Offset(svgX, svgY) en píxeles del SVG
  static Offset sensorPositionToSvg({
    required double posX,
    required double posY,
    required double initialSvgX,
    required double initialSvgY,
  }) {
    // Convertir metros a píxeles
    final dxPx = posX / _calibratedMetersPerPixel;
    final dyPx = posY / _calibratedMetersPerPixel;
    
    // Aplicar al punto inicial
    return Offset(initialSvgX + dxPx, initialSvgY - dyPx); // Negativo en Y porque el SVG tiene Y hacia abajo
  }
  
  /// Encontrar el nodo más cercano a una posición del sensor
  /// 
  /// [posX, posY] - Posición relativa en metros desde el punto inicial
  /// [initialSvgX, initialSvgY] - Coordenadas SVG del punto inicial
  /// [nodes] - Lista de nodos disponibles
  /// 
  /// Retorna: El nodo más cercano a la posición calculada
  static MapNode? findNearestNode({
    required double posX,
    required double posY,
    required double initialSvgX,
    required double initialSvgY,
    required List<MapNode> nodes,
  }) {
    if (nodes.isEmpty) return null;
    
    // Convertir posición del sensor a coordenadas SVG
    final svgPos = sensorPositionToSvg(
      posX: posX,
      posY: posY,
      initialSvgX: initialSvgX,
      initialSvgY: initialSvgY,
    );
    
    // Encontrar nodo más cercano
    MapNode? nearest;
    double minDistance = double.infinity;
    
    for (final node in nodes) {
      final dx = node.x - svgPos.dx;
      final dy = node.y - svgPos.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = node;
      }
    }
    
    return nearest;
  }
  
  /// Calcular distancia real entre dos nodos en metros
  static double distanceInMeters(MapNode node1, MapNode node2) {
    final distPx = node1.distanceToReal(node2);
    return pixelsToMeters(distPx);
  }
  
  /// Limpiar todos los puntos de referencia
  static void clearReferencePoints() {
    _referencePoints.clear();
    _calibratedMetersPerPixel = _estimatedMetersPerPixel;
  }
  
  /// Obtener información de calibración actual
  static Map<String, dynamic> getCalibrationInfo() {
    return {
      'metersPerPixel': _calibratedMetersPerPixel,
      'pixelsPerMeter': getPixelsPerMeter(),
      'referencePointsCount': _referencePoints.length,
      'isCalibrated': _referencePoints.length >= 2,
      'svgDimensions': {
        'width': svgWidth,
        'height': svgHeight,
      },
      'estimatedRealDimensions': {
        'widthMeters': pixelsToMeters(svgWidth),
        'heightMeters': pixelsToMeters(svgHeight),
      },
    };
  }
}

