import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/entities/map_floor.dart';

/// Fuente de datos para parsear mapas SVG y extraer nodos
class SvgMapDataSource {
  /// Parsea un archivo SVG y extrae los nodos del piso especificado
  /// 
  /// [floor] El número de piso
  /// [assetPath] Ruta del archivo SVG en assets (ej: 'assets/mapas/MAP_PISO_1.svg')
  /// 
  /// Retorna una lista de MapNode extraídos del SVG
  Future<List<MapNode>> parseFloorSvg({
    required int floor,
    required String assetPath,
  }) async {
    // Leer el archivo SVG desde assets
    final String svgContent = await rootBundle.loadString(assetPath);

    // Parsear el XML
    final document = XmlDocument.parse(svgContent);
    final root = document.rootElement;

    // Buscar el grupo de nodos (puede ser "NODES" o "nodes#")
    XmlElement? nodesGroup;
    try {
      nodesGroup = root.findAllElements('g').firstWhere(
        (element) {
          final id = element.getAttribute('id');
          return id == 'NODES' || id == 'nodes#' || (id != null && id.toLowerCase().contains('nodes'));
        },
      );
    } catch (e) {
      final allGroups = root.findAllElements('g').map((e) => e.getAttribute('id')).whereType<String>().toList();
      throw Exception(
        'No se encontró el grupo NODES en el SVG. '
        'Grupos encontrados: ${allGroups.join(", ")}',
      );
    }

    // Lista para almacenar los nodos encontrados
    final List<MapNode> nodes = [];

    // Recorrer todos los <circle> dentro de NODES
    for (final circle in nodesGroup.findAllElements('circle')) {
      final id = circle.getAttribute('id');
      if (id == null || id.isEmpty) continue;

      final cxStr = circle.getAttribute('cx');
      final cyStr = circle.getAttribute('cy');

      if (cxStr == null || cyStr == null) continue;

      final cx = double.tryParse(cxStr);
      final cy = double.tryParse(cyStr);

      if (cx == null || cy == null) continue;

      // Determinar type y refId basado en el id
      final String? type;
      final String? refId;

      final idLower = id.toLowerCase();
      if (idLower.contains('sal')) {
        type = 'salon';
        refId = id; // El id mismo puede ser la referencia
      } else if (idLower.contains('bano')) {
        type = 'bano';
        refId = id;
      } else if (idLower.contains('escalera')) {
        type = 'escalera';
        refId = id;
      } else {
        type = 'pasillo';
        refId = null;
      }

      // Crear el MapNode
      final node = MapNode(
        id: id,
        x: cx,
        y: cy,
        floor: floor,
        type: type,
        refId: refId,
      );

      nodes.add(node);
    }
    
    final allPaths = nodesGroup.findAllElements('path').toList();
    for (final path in allPaths) {
      final id = path.getAttribute('id');
      if (id == null || id.isEmpty) continue;

      if (!id.startsWith('node_')) {
        continue;
      }

      // Intentar extraer coordenadas del atributo 'd'
      // Para paths con círculos, el formato es: M x y C x y x y x y x y x y x y Z
      // O simplemente: M x y ... donde x, y es el centro
      final d = path.getAttribute('d');
      if (d == null || d.isEmpty) continue;

      // Extraer coordenadas del path
      // El formato del path para node_puerta_comedor es: M836 978C836 983.523...
      // El punto M836 978 es el centro del círculo
      // Regex para capturar: M seguido de número, espacio, número
      final match = RegExp(r'M\s*(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)').firstMatch(d);
      
      if (match == null) {
        continue;
      }

      final cx = double.tryParse(match.group(1)!);
      final cy = double.tryParse(match.group(2)!);
      
      if (cx == null || cy == null) {
        continue;
      }

      // Determinar type y refId basado en el id
      final String? type;
      final String? refId;

      final idLower = id.toLowerCase();
      if (idLower.contains('sal')) {
        type = 'salon';
        refId = id;
      } else if (idLower.contains('bano')) {
        type = 'bano';
        refId = id;
      } else if (idLower.contains('escalera')) {
        type = 'escalera';
        refId = id;
      } else if (idLower.contains('puerta')) {
        type = 'pasillo';
        refId = id;
      } else {
        type = 'pasillo';
        refId = null;
      }

      // Crear el MapNode
      final node = MapNode(
        id: id,
        x: cx,
        y: cy,
        floor: floor,
        type: type,
        refId: refId,
      );

      nodes.add(node);
    }
    

    return nodes;
  }

  /// Construye un MapFloor completo desde un archivo SVG
  /// 
  /// Por ahora solo parsea nodos, los edges se definirán manualmente más adelante
  /// 
  /// [floor] El número de piso
  /// [assetPath] Ruta del archivo SVG en assets
  /// 
  /// Retorna un MapFloor con los nodos parseados y edges vacíos
  Future<MapFloor> buildFloorFromSvg({
    required int floor,
    required String assetPath,
  }) async {
    final nodes = await parseFloorSvg(floor: floor, assetPath: assetPath);

    return MapFloor(
      floor: floor,
      nodes: nodes,
      edges: const [], // Edges vacíos por ahora
    );
  }
}

