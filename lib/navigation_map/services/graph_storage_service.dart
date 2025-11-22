import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_node.dart';
import '../models/edge.dart';
import '../config/graph_edges_config.dart';

/// Servicio para almacenar y recuperar el grafo de navegación desde Firestore
/// Estructura: /mapas/piso_X/nodes y /mapas/piso_X/edges
class GraphStorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda los nodos de un piso en Firestore
  /// 
  /// Estructura: /mapas/piso_X/nodes/{nodeId}
  Future<void> saveNodes({
    required int piso,
    required List<MapNode> nodes,
  }) async {
    try {
      print('💾 Guardando ${nodes.length} nodos del piso $piso en Firestore...');
      
      final batch = _db.batch();
      final nodesRef = _db.collection('mapas').doc('piso_$piso').collection('nodes');
      
      for (final node in nodes) {
        final docRef = nodesRef.doc(node.id);
        batch.set(docRef, node.toJson());
      }
      
      await batch.commit();
      print('✅ Nodos del piso $piso guardados correctamente');
    } catch (e) {
      print('❌ Error al guardar nodos del piso $piso: $e');
      rethrow;
    }
  }

  /// Guarda las conexiones (edges) de un piso en Firestore
  /// 
  /// Estructura: /mapas/piso_X/edges/{edgeId}
  Future<void> saveEdges({
    required int piso,
    required List<Edge> edges,
  }) async {
    try {
      print('💾 Guardando ${edges.length} edges del piso $piso en Firestore...');
      
      final batch = _db.batch();
      final edgesRef = _db.collection('mapas').doc('piso_$piso').collection('edges');
      
      for (final edge in edges) {
        // Usar un ID único para cada edge (fromId_toId)
        final edgeId = '${edge.fromId}_${edge.toId}';
        final docRef = edgesRef.doc(edgeId);
        batch.set(docRef, edge.toJson());
      }
      
      await batch.commit();
      print('✅ Edges del piso $piso guardados correctamente');
    } catch (e) {
      print('❌ Error al guardar edges del piso $piso: $e');
      rethrow;
    }
  }

  /// Carga todos los nodos de un piso desde Firestore
  Future<List<MapNode>> loadNodes(int piso) async {
    try {
      final snapshot = await _db
          .collection('mapas')
          .doc('piso_$piso')
          .collection('nodes')
          .get();
      
      return snapshot.docs
          .map((doc) => MapNode.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error al cargar nodos del piso $piso: $e');
      rethrow;
    }
  }

  /// Carga todas las conexiones (edges) de un piso desde Firestore
  Future<List<Edge>> loadEdges(int piso) async {
    try {
      final snapshot = await _db
          .collection('mapas')
          .doc('piso_$piso')
          .collection('edges')
          .get();
      
      return snapshot.docs
          .map((doc) => Edge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error al cargar edges del piso $piso: $e');
      rethrow;
    }
  }

  /// Carga nodos y edges de un piso
  /// Para piso 2, SOLO usa edges manuales (ignora cualquier edge adicional en Firestore)
  /// Si no hay edges en Firestore, los inicializa automáticamente
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    final nodes = await loadNodes(piso);
    var edges = await loadEdges(piso);
    
    // Para piso 2, SIEMPRE usar solo edges manuales (ignorar edges adicionales en Firestore)
    if (piso == 2) {
      print('📋 Piso 2: Forzando uso de edges MANUALES únicamente');
      // Nota: Para piso 2, necesitamos el SVG path para extraer shapes
      // Si no lo tenemos aquí, los edges se generarán sin shapes
      // Los shapes se agregarán cuando se reinicialice el grafo completo
      final manualEdges = await GraphEdgesConfig.getManualEdgesForFloor(piso, nodes);
      
      if (manualEdges.isNotEmpty) {
        // Verificar si los edges en Firestore coinciden con los manuales
        final manualEdgeIds = manualEdges.map((e) => '${e.fromId}_${e.toId}').toSet();
        final firestoreEdgeIds = edges.map((e) => '${e.fromId}_${e.toId}').toSet();
        
        if (manualEdgeIds != firestoreEdgeIds) {
          print('⚠️ Edges en Firestore no coinciden con edges manuales. Actualizando Firestore...');
          // Limpiar edges antiguos y guardar solo los manuales
          await clearEdges(piso);
          edges = manualEdges;
          await saveEdges(piso: piso, edges: edges);
          print('✅ Firestore actualizado con edges manuales únicamente');
        } else {
          edges = manualEdges; // Usar los manuales aunque coincidan (asegurar consistencia)
          print('✅ Usando edges manuales (${edges.length} edges)');
        }
      } else {
        print('❌ No se pudieron generar edges manuales para piso 2');
      }
    } else {
      // Para otros pisos, si no hay edges, inicializarlos automáticamente
      if (edges.isEmpty && nodes.isNotEmpty) {
        print('⚠️ No se encontraron edges en Firestore para piso $piso. Inicializando automáticamente...');
        final manualEdges = await GraphEdgesConfig.getManualEdgesForFloor(piso, nodes);
        if (manualEdges.isNotEmpty) {
          edges = manualEdges;
          await saveEdges(piso: piso, edges: edges);
          print('✅ Edges inicializados y guardados en Firestore para piso $piso');
        } else {
          print('⚠️ No hay edges manuales definidos para piso $piso');
        }
      }
    }
    
    print('📊 Total de edges que se usarán: ${edges.length}');
    
    return {
      'nodes': nodes,
      'edges': edges,
    };
  }
  
  /// Limpia solo los edges de un piso (mantiene los nodos)
  Future<void> clearEdges(int piso) async {
    try {
      print('🧹 Limpiando edges del piso $piso...');
      final edgesRef = _db.collection('mapas').doc('piso_$piso').collection('edges');
      final snapshot = await edgesRef.get();
      
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Edges del piso $piso eliminados');
    } catch (e) {
      print('❌ Error al limpiar edges del piso $piso: $e');
      rethrow;
    }
  }

  /// Limpia todos los nodos y edges de un piso
  Future<void> clearFloor(int piso) async {
    try {
      // Eliminar edges primero
      final edgesSnapshot = await _db
          .collection('mapas')
          .doc('piso_$piso')
          .collection('edges')
          .get();
      
      final edgesBatch = _db.batch();
      for (final doc in edgesSnapshot.docs) {
        edgesBatch.delete(doc.reference);
      }
      await edgesBatch.commit();
      
      // Eliminar nodos
      final nodesSnapshot = await _db
          .collection('mapas')
          .doc('piso_$piso')
          .collection('nodes')
          .get();
      
      final nodesBatch = _db.batch();
      for (final doc in nodesSnapshot.docs) {
        nodesBatch.delete(doc.reference);
      }
      await nodesBatch.commit();
      
      print('✅ Piso $piso limpiado correctamente');
    } catch (e) {
      print('❌ Error al limpiar piso $piso: $e');
      rethrow;
    }
  }

  /// Busca un nodo por ID en un piso específico
  Future<MapNode?> findNodeById(int piso, String nodeId) async {
    try {
      final doc = await _db
          .collection('mapas')
          .doc('piso_$piso')
          .collection('nodes')
          .doc(nodeId)
          .get();
      
      if (doc.exists) {
        return MapNode.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error al buscar nodo $nodeId en piso $piso: $e');
      return null;
    }
  }

  /// Busca el nodo de entrada principal de un piso
  Future<MapNode?> findEntranceNode(int piso) async {
    try {
      final nodes = await loadNodes(piso);
      
      // Buscar nodo con tipo "entrada" o ID que contenga "entrada", "inicio", "punto-inicial"
      return nodes.firstWhere(
        (node) =>
            node.tipo == 'entrada' ||
            node.id.toLowerCase().contains('entrada') ||
            node.id.toLowerCase().contains('inicio') ||
            node.id.toLowerCase().contains('punto-inicial'),
        orElse: () => nodes.first, // Si no hay entrada, usar el primer nodo
      );
    } catch (e) {
      print('❌ Error al buscar nodo de entrada en piso $piso: $e');
      return null;
    }
  }
}

