import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/map_node_model.dart';
import 'dart:math' as math;

/// Servicio para parsear salones desde SVG y asociarlos con nodos
class SvgSalonParser {
  /// Parsea los salones (rooms) del SVG y encuentra el nodo más cercano a cada uno
  /// 
  /// [svgPath] - Ruta del archivo SVG
  /// [nodes] - Lista de nodos ya parseados
  /// [piso] - Número de piso
  /// 
  /// Retorna un mapa: {salonId: nodeId}
  static Future<Map<String, String>> parseSalonsAndMapToNodes({
    required String svgPath,
    required List<MapNodeModel> nodes,
    required int piso,
  }) async {
    try {
      // Cargar el contenido del SVG
      final String svgContent = await rootBundle.loadString(svgPath);
      
      // Parsear el XML
      final document = XmlDocument.parse(svgContent);
      
      // Buscar el grupo de salones
      final salonesGroup = document.findAllElements('g').firstWhere(
        (element) => element.getAttribute('id') == 'Salones',
        orElse: () => throw Exception('No se encontró el grupo Salones en el SVG'),
      );
      
      // Extraer todos los paths de salones
      final salones = salonesGroup.findAllElements('path');
      
      final Map<String, String> salonToNodeMap = {};
      
      for (final salon in salones) {
        final salonId = salon.getAttribute('id');
        if (salonId == null) continue;
        
        // Normalizar el ID a minúsculas para comparación
        final normalizedId = salonId.toLowerCase();
        
        // Verificar si el ID ya tiene el formato correcto: salon-{TORRE}-{NUMERO} o room-{TORRE}-{NUMERO}
        String? formattedSalonId;
        
        if (normalizedId.startsWith('salon-')) {
          // Ya tiene el formato correcto: salon-A-200
          formattedSalonId = salonId; // Mantener el formato original (case-sensitive)
        } else if (normalizedId.startsWith('room-')) {
          // Formato room-{TORRE}-{NUMERO}: convertir a salon-{TORRE}-{NUMERO}
          formattedSalonId = salonId.replaceFirst(RegExp(r'^room-', caseSensitive: false), 'salon-');
        } else if (normalizedId.startsWith('room')) {
          // Formato antiguo: room01, room02, etc. - usar formato legacy
          formattedSalonId = _formatSalonId(salonId, piso);
        } else {
          // No es un formato reconocido, saltar
          continue;
        }
        
        // PRIORIDAD 1: Buscar nodo especial del salón (formato: node-salon-{TORRE}-{NUMERO})
        final salonNodeId = 'node-$formattedSalonId';
        try {
          final salonNode = nodes.firstWhere((n) => n.id == salonNodeId);
          salonToNodeMap[formattedSalonId] = salonNode.id;
          print('✅ Salón detectado con nodo especial: $salonId -> $formattedSalonId -> Nodo ${salonNode.id}');
          continue; // Ya encontramos el nodo, no necesitamos buscar el más cercano
        } catch (e) {
          // No hay nodo especial, continuar con búsqueda del más cercano
        }
        
        // PRIORIDAD 2: Si no hay nodo especial, buscar el nodo más cercano al centro del salón
        // Calcular el centro del salón desde el path
        final pathData = salon.getAttribute('d');
        if (pathData == null) continue;
        
        // Extraer coordenadas del path (aproximación simple)
        final coords = _extractCenterFromPath(pathData);
        if (coords == null) continue;
        
        // Encontrar el nodo más cercano
        final nearestNode = _findNearestNode(coords, nodes);
        if (nearestNode != null) {
          salonToNodeMap[formattedSalonId] = nearestNode.id;
          print('✅ Salón detectado: $salonId -> $formattedSalonId -> Nodo más cercano ${nearestNode.id}');
        }
      }
      
      print('✅ Mapeados ${salonToNodeMap.length} salones a nodos');
      return salonToNodeMap;
    } catch (e) {
      print('❌ Error al parsear salones: $e');
      return {};
    }
  }

  /// Extrae el centro aproximado de un path SVG
  static Offset? _extractCenterFromPath(String pathData) {
    // Extraer todos los números del path
    final numbers = RegExp(r'-?\d+\.?\d*').allMatches(pathData);
    if (numbers.isEmpty) return null;
    
    final coords = numbers.map((m) => double.tryParse(m.group(0)!) ?? 0.0).toList();
    if (coords.length < 2) return null;
    
    // Calcular promedio de X e Y (aproximación del centro)
    double sumX = 0, sumY = 0;
    int count = 0;
    
    for (int i = 0; i < coords.length; i += 2) {
      if (i + 1 < coords.length) {
        sumX += coords[i];
        sumY += coords[i + 1];
        count++;
      }
    }
    
    if (count == 0) return null;
    
    return Offset(sumX / count, sumY / count);
  }

  /// Encuentra el nodo más cercano a un punto
  static MapNodeModel? _findNearestNode(Offset point, List<MapNodeModel> nodes) {
    if (nodes.isEmpty) return null;
    
    MapNodeModel? nearest;
    double minDistance = double.infinity;
    
    for (final node in nodes) {
      final dx = node.x - point.dx;
      final dy = node.y - point.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = node;
      }
    }
    
    return nearest;
  }

  /// Formatea el ID del salón desde roomXX a salon-A-XXX
  static String _formatSalonId(String roomId, int piso) {
    // Extraer número del room (ej: "room13" -> "13")
    final numberMatch = RegExp(r'\d+').firstMatch(roomId);
    if (numberMatch == null) return roomId;
    
    final number = numberMatch.group(0)!;
    
    // Mapeo aproximado: room01-13 -> salones A-101 a A-113
    // Asumir Torre A por defecto
    return 'salon-A-$number';
  }
}

