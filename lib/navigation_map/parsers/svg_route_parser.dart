import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'dart:math' as math;

/// Servicio para parsear la ruta física del SVG
/// La ruta define el camino real por donde los estudiantes caminan
class SvgRouteParser {
  /// Parsea el path de la ruta desde el SVG
  /// 
  /// [svgPath] - Ruta del archivo SVG
  /// 
  /// Retorna una lista de puntos (Offset) que representan la ruta física
  static Future<List<Offset>> parseRoutePath(String svgPath) async {
    try {
      // Cargar el contenido del SVG
      final String svgContent = await rootBundle.loadString(svgPath);
      
      // Parsear el XML
      final document = XmlDocument.parse(svgContent);
      
      // Buscar el grupo "Ruta"
      final routeGroup = document.findAllElements('g').firstWhere(
        (element) {
          final id = element.getAttribute('id');
          return id != null && id.toLowerCase() == 'ruta';
        },
        orElse: () => throw Exception('No se encontró el grupo Ruta en el SVG'),
      );
      
      // Buscar el path dentro del grupo
      final routePath = routeGroup.findAllElements('path').firstOrNull;
      if (routePath == null) {
        throw Exception('No se encontró el path en el grupo Ruta');
      }
      
      final pathData = routePath.getAttribute('d');
      if (pathData == null) {
        throw Exception('El path de la ruta no tiene atributo d');
      }
      
      // Extraer puntos del path
      final points = _extractPointsFromPath(pathData);
      
      print('✅ Ruta física parseada: ${points.length} puntos');
      return points;
    } catch (e) {
      print('❌ Error al parsear ruta del SVG: $e');
      return [];
    }
  }
  
  /// Extrae puntos del path SVG
  /// Maneja comandos: M, L, H, V, Z
  static List<Offset> _extractPointsFromPath(String pathData) {
    final points = <Offset>[];
    
    // Parsear comandos del path SVG
    // Comandos: M (moveto), L (lineto), H (horizontal), V (vertical), Z (closepath)
    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    
    // Dividir por comandos
    final commandPattern = RegExp(r'([MmLlHhVvZz])\s*([^MmLlHhVvZz]*)');
    final matches = commandPattern.allMatches(pathData);
    
    for (final match in matches) {
      final command = match.group(1)!;
      final data = match.group(2)!.trim();
      
      // Extraer números del comando
      final numbers = RegExp(r'-?\d+\.?\d*').allMatches(data);
      final coords = numbers.map((m) => double.tryParse(m.group(0)!) ?? 0.0).toList();
      
      switch (command.toUpperCase()) {
        case 'M': // Moveto absoluto
          if (coords.length >= 2) {
            currentX = coords[0];
            currentY = coords[1];
            startX = currentX;
            startY = currentY;
            points.add(Offset(currentX, currentY));
            
            // Procesar coordenadas adicionales como L (lineto implícito)
            for (int i = 2; i < coords.length - 1; i += 2) {
              currentX = coords[i];
              currentY = coords[i + 1];
              points.add(Offset(currentX, currentY));
            }
          }
          break;
          
        case 'L': // Lineto absoluto
          for (int i = 0; i < coords.length - 1; i += 2) {
            currentX = coords[i];
            currentY = coords[i + 1];
            points.add(Offset(currentX, currentY));
          }
          break;
          
        case 'H': // Horizontal lineto
          for (final x in coords) {
            currentX = x;
            points.add(Offset(currentX, currentY));
          }
          break;
          
        case 'V': // Vertical lineto
          for (final y in coords) {
            currentY = y;
            points.add(Offset(currentX, currentY));
          }
          break;
          
        case 'Z': // Closepath
          // Conectar de vuelta al punto inicial
          if (points.isNotEmpty && (currentX != startX || currentY != startY)) {
            points.add(Offset(startX, startY));
            currentX = startX;
            currentY = startY;
          }
          break;
      }
    }
    
    // Si no se encontraron puntos con comandos, intentar extraer todos los pares de números
    if (points.isEmpty) {
      final allNumbers = RegExp(r'-?\d+\.?\d*').allMatches(pathData);
      final allCoords = allNumbers.map((m) => double.tryParse(m.group(0)!) ?? 0.0).toList();
      
      for (int i = 0; i < allCoords.length - 1; i += 2) {
        points.add(Offset(allCoords[i], allCoords[i + 1]));
      }
    }
    
    return points;
  }
  
  /// Calcula la distancia mínima de un punto a la ruta
  /// 
  /// [point] - Punto a verificar
  /// [routePoints] - Lista de puntos que forman la ruta
  /// 
  /// Retorna la distancia mínima al path de la ruta
  static double distanceToRoute(Offset point, List<Offset> routePoints) {
    if (routePoints.isEmpty) return double.infinity;
    if (routePoints.length == 1) {
      final dx = point.dx - routePoints[0].dx;
      final dy = point.dy - routePoints[0].dy;
      return math.sqrt(dx * dx + dy * dy);
    }
    
    double minDistance = double.infinity;
    
    // Calcular distancia a cada segmento de la ruta
    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];
      
      final distance = _distanceToSegment(point, p1, p2);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }
  
  /// Calcula la distancia de un punto a un segmento de línea
  static double _distanceToSegment(Offset point, Offset segStart, Offset segEnd) {
    final A = point.dx - segStart.dx;
    final B = point.dy - segStart.dy;
    final C = segEnd.dx - segStart.dx;
    final D = segEnd.dy - segStart.dy;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) {
      // Segmento es un punto
      final dx = point.dx - segStart.dx;
      final dy = point.dy - segStart.dy;
      return math.sqrt(dx * dx + dy * dy);
    }
    
    final param = dot / lenSq;
    
    double xx, yy;
    
    if (param < 0) {
      xx = segStart.dx;
      yy = segStart.dy;
    } else if (param > 1) {
      xx = segEnd.dx;
      yy = segEnd.dy;
    } else {
      xx = segStart.dx + param * C;
      yy = segStart.dy + param * D;
    }
    
    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Verifica si un punto está cerca de la ruta (dentro de un umbral)
  static bool isNearRoute(Offset point, List<Offset> routePoints, double threshold) {
    return distanceToRoute(point, routePoints) <= threshold;
  }
  
  /// Verifica si un SEGMENTO COMPLETO está dentro de la ruta física
  /// Esto actúa como "paredes" que impiden saltos diagonales
  /// 
  /// [segmentStart] - Punto inicial del segmento
  /// [segmentEnd] - Punto final del segmento
  /// [routePoints] - Puntos de la ruta física
  /// [maxDeviation] - Máxima desviación permitida de la ruta (en píxeles)
  /// 
  /// Retorna true si TODO el segmento está dentro de la ruta (como un pasillo)
  static bool isSegmentInsideRoute(
    Offset segmentStart,
    Offset segmentEnd,
    List<Offset> routePoints,
    double maxDeviation,
  ) {
    if (routePoints.isEmpty) return false;
    
    // Muestrear muchos puntos a lo largo del segmento (más denso)
    // Esto asegura que detectemos si el segmento cruza fuera de la ruta
    const int samples = 20; // 20 puntos de muestreo
    
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final point = Offset(
        segmentStart.dx + (segmentEnd.dx - segmentStart.dx) * t,
        segmentStart.dy + (segmentEnd.dy - segmentStart.dy) * t,
      );
      
      // Verificar que este punto esté dentro de la ruta
      final distance = distanceToRoute(point, routePoints);
      
      // Si cualquier punto del segmento está fuera de la ruta, rechazar
      if (distance > maxDeviation) {
        return false;
      }
    }
    
    // Todos los puntos del segmento están dentro de la ruta
    return true;
  }
  
  /// Encuentra el índice del punto más cercano en la ruta
  /// Útil para ordenar nodos según su posición en la ruta
  static int findClosestRoutePointIndex(Offset point, List<Offset> routePoints) {
    if (routePoints.isEmpty) return 0;
    
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < routePoints.length; i++) {
      final dx = point.dx - routePoints[i].dx;
      final dy = point.dy - routePoints[i].dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }
  
  /// Extrae el segmento de la ruta física entre dos nodos
  /// Retorna los puntos del SVG que están entre estos dos nodos
  /// 
  /// [fromNode] - Nodo origen
  /// [toNode] - Nodo destino
  /// [routePoints] - Todos los puntos de la ruta física del SVG
  /// 
  /// Retorna una lista de puntos que representan el segmento entre los nodos
  static List<Offset> extractSegmentBetweenNodes(
    Offset fromNode,
    Offset toNode,
    List<Offset> routePoints,
  ) {
    if (routePoints.isEmpty) {
      // Si no hay ruta, retornar solo los dos nodos
      return [fromNode, toNode];
    }
    
    // Encontrar los índices más cercanos en la ruta para cada nodo
    final fromIndex = findClosestRoutePointIndex(fromNode, routePoints);
    final toIndex = findClosestRoutePointIndex(toNode, routePoints);
    
    // Determinar la dirección (adelante o atrás)
    final startIndex = fromIndex < toIndex ? fromIndex : toIndex;
    final endIndex = fromIndex < toIndex ? toIndex : fromIndex;
    
    // Extraer el segmento de la ruta
    final segment = <Offset>[];
    
    // Incluir el punto del nodo origen
    segment.add(fromNode);
    
    // Incluir todos los puntos de la ruta entre los índices
    for (int i = startIndex; i <= endIndex && i < routePoints.length; i++) {
      segment.add(routePoints[i]);
    }
    
    // Incluir el punto del nodo destino
    segment.add(toNode);
    
    return segment;
  }

  /// Calcula la posición relativa de un punto en la ruta (0.0 a 1.0)
  /// 0.0 = inicio de la ruta, 1.0 = fin de la ruta
  static double getRoutePosition(Offset point, List<Offset> routePoints) {
    if (routePoints.isEmpty) return 0.0;
    
    final index = findClosestRoutePointIndex(point, routePoints);
    return index / (routePoints.length - 1).clamp(1, double.infinity);
  }
}

