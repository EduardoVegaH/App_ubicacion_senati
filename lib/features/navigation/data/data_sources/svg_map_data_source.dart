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

    // Buscar el grupo <g id="NODES">
    final nodesGroup = root.findAllElements('g').firstWhere(
      (element) => element.getAttribute('id') == 'NODES',
      orElse: () => throw Exception('No se encontró el grupo NODES en el SVG'),
    );

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

    // También buscar <path> que puedan representar nodos (como node_puerta_comedor)
    for (final path in nodesGroup.findAllElements('path')) {
      final id = path.getAttribute('id');
      if (id == null || id.isEmpty) continue;

      // Extraer coordenadas del path (buscar el atributo d o transform)
      // Por ahora, si tiene id que empiece con "node_", intentamos extraerlo
      if (!id.startsWith('node_')) continue;

      // Intentar extraer coordenadas del atributo 'd' o 'transform'
      // Para simplificar, si no podemos extraer coordenadas, lo omitimos
      // Esto se puede mejorar más adelante
      final transform = path.getAttribute('transform');
      final d = path.getAttribute('d');

      // Si no hay coordenadas claras, omitir este path por ahora
      // (Se puede mejorar el parsing más adelante)
      if (transform == null && d == null) continue;

      // Por ahora, si es un path con id de nodo pero sin coordenadas claras,
      // lo omitimos. Se puede mejorar el parsing más adelante.
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

