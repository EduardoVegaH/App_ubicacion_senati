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
  /// OPTIMIZACIÓN: Evita verificaciones innecesarias en tiempo de carga
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    final nodes = await loadNodes(piso);
    var edges = await loadEdges(piso);
    
    // Para piso 2, SIEMPRE usar solo edges manuales (ignorar edges adicionales en Firestore)
    if (piso == 2) {
      print('📋 Piso 2: Forzando uso de edges MANUALES únicamente');
      // OPTIMIZACIÓN: No cargar SVG aquí para evitar latencia - los edges ya tienen shapes si fueron inicializados
      // Solo cargar SVG si realmente es necesario (cuando se inicializa el grafo, no en cada carga)
      final manualEdges = await GraphEdgesConfig.getManualEdgesForFloor(piso, nodes, svgPath: null);
      
      if (manualEdges.isNotEmpty) {
        // OPTIMIZACIÓN: Solo verificar si hay edges en Firestore, no comparar todos los IDs
        // Si hay edges en Firestore, asumimos que están correctos (la verificación completa se hace en inicialización)
        if (edges.isEmpty || edges.length != manualEdges.length) {
          // Si no hay edges o el número no coincide, usar los manuales directamente
          // No actualizar Firestore aquí para evitar latencia - se actualiza en inicialización
          edges = manualEdges;
          print('✅ Usando edges manuales (${edges.length} edges) - Firestore se actualizará en inicialización');
        } else {
          // Si hay edges y el número coincide, usar los manuales para asegurar consistencia
          edges = manualEdges;
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
          // OPTIMIZACIÓN: Guardar en background para no bloquear la carga
          saveEdges(piso: piso, edges: edges).catchError((e) {
            print('⚠️ Error al guardar edges en background: $e');
          });
          print('✅ Edges inicializados para piso $piso (guardando en background)');
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
  /// OPTIMIZACIÓN: Acepta nodos ya cargados para evitar consulta adicional
  Future<MapNode?> findEntranceNode(int piso, {List<MapNode>? nodes}) async {
    try {
      final nodeList = nodes ?? await loadNodes(piso);
      if (nodeList.isEmpty) return null;
      
      // Buscar nodo con tipo "entrada" o ID que contenga "entrada", "inicio", "punto-inicial"
      try {
        return nodeList.firstWhere(
          (node) =>
              node.tipo == 'entrada' ||
              node.id.toLowerCase().contains('entrada') ||
              node.id.toLowerCase().contains('inicio') ||
              node.id.toLowerCase().contains('punto-inicial'),
        );
      } catch (e) {
        // Si no hay entrada, usar el primer nodo
        return nodeList.first;
      }
    } catch (e) {
      print('❌ Error al buscar nodo de entrada en piso $piso: $e');
      return null;
    }
  }
}

