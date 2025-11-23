import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/map_node.dart';

/// Servicio para parsear nodos desde archivos SVG
/// Extrae los <circle> con id, cx, cy del SVG
class SvgNodeParser {
  /// Parsea un archivo SVG y extrae todos los nodos (circles)
  /// 
  /// [svgPath] - Ruta del archivo SVG en assets (ej: "assets/mapas/map_ext.svg")
  /// [piso] - Número de piso al que pertenece el mapa
  /// 
  /// Retorna una lista de MapNode con todos los nodos encontrados
  static Future<List<MapNode>> parseNodesFromSvg({
    required String svgPath,
    required int piso,
  }) async {
    try {
      // Cargar el contenido del SVG
      final String svgContent = await rootBundle.loadString(svgPath);
      
      // Parsear el XML
      final document = XmlDocument.parse(svgContent);
      
      // Buscar todos los elementos <circle> dentro de un grupo con id="NODES"
      final nodesGroup = document.findAllElements('g').firstWhere(
        (element) => element.getAttribute('id') == 'NODES',
        orElse: () => throw Exception('No se encontró el grupo NODES en el SVG'),
      );
      
      // Extraer todos los circles
      final circles = nodesGroup.findAllElements('circle');
      
      final List<MapNode> mapNodes = [];
      
      for (final circle in circles) {
        final id = circle.getAttribute('id');
        final cxStr = circle.getAttribute('cx');
        final cyStr = circle.getAttribute('cy');
        
        if (id == null || cxStr == null || cyStr == null) {
          print('⚠️ Advertencia: Circle sin id, cx o cy, se omite');
          continue;
        }
        
        try {
          final x = double.parse(cxStr);
          final y = double.parse(cyStr);
          
          // Detectar tipo de nodo basado en el ID
          String? tipo;
          String? salonId;
          
          // Detectar nodos especiales de salones (formato: node-salon-{TORRE}-{NUMERO})
          final salonNodeMatch = RegExp(r'node-salon-([A-Z])-(\d+)', caseSensitive: false).firstMatch(id);
          if (salonNodeMatch != null) {
            final torre = salonNodeMatch.group(1)!.toUpperCase();
            final numero = salonNodeMatch.group(2)!;
            salonId = 'salon-$torre-$numero';
            tipo = 'salon';
            print('✅ Detectado nodo especial de salón: $id -> $salonId');
          } else if (id.toLowerCase().contains('entrada') || 
                     id.toLowerCase().contains('inicio') ||
                     id.toLowerCase().contains('punto-inicial')) {
            tipo = 'entrada';
          } else if (id.toLowerCase().contains('escalera')) {
            tipo = 'escalera';
          } else if (id.toLowerCase().contains('ascensor') || 
                     id.toLowerCase().contains('asensor')) {
            tipo = 'ascensor';
          } else if (id.toLowerCase().contains('pasillo')) {
            tipo = 'pasillo';
          } else if (id.toLowerCase().contains('salon') || 
                     id.toLowerCase().contains('room')) {
            tipo = 'salon';
          }
          
          mapNodes.add(MapNode(
            id: id,
            x: x,
            y: y,
            piso: piso,
            tipo: tipo,
            salonId: salonId, // Asignar salonId si es un nodo especial
          ));
        } catch (e) {
          print('⚠️ Error al parsear coordenadas del nodo $id: $e');
        }
      }
      
      print('✅ Parseados ${mapNodes.length} nodos del SVG $svgPath');
      return mapNodes;
    } catch (e) {
      print('❌ Error al parsear SVG $svgPath: $e');
      rethrow;
    }
  }

  /// Parsea múltiples archivos SVG y retorna todos los nodos agrupados por piso
  static Future<Map<int, List<MapNode>>> parseAllSvgs({
    required Map<int, String> svgPaths, // {1: "assets/mapas/map_ext.svg", 2: "assets/mapas/map_int_piso2.svg"}
  }) async {
    final Map<int, List<MapNode>> nodesByFloor = {};
    
    for (final entry in svgPaths.entries) {
      final piso = entry.key;
      final svgPath = entry.value;
      
      try {
        final nodes = await parseNodesFromSvg(svgPath: svgPath, piso: piso);
        nodesByFloor[piso] = nodes;
      } catch (e) {
        print('❌ Error al parsear piso $piso: $e');
      }
    }
    
    return nodesByFloor;
  }
}

