import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/map_node_model.dart';
import '../models/edge_model.dart';

/// Servicio para almacenar y recuperar el grafo de navegación desde Firestore
/// Estructura: /mapas/piso_X/nodes y /mapas/piso_X/edges
class GraphStorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda los nodos de un piso en Firestore
  Future<void> saveNodes({
    required int piso,
    required List<MapNodeModel> nodes,
  }) async {
    try {
      print('💾 Guardando ${nodes.length} nodos del piso $piso en Firestore...');
      
      final batch = _db.batch();
      final nodesRef = _db.collection(AppConstants.mapasCollection).doc('piso_$piso').collection('nodes');
      
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
  Future<void> saveEdges({
    required int piso,
    required List<EdgeModel> edges,
  }) async {
    try {
      print('💾 Guardando ${edges.length} edges del piso $piso en Firestore...');
      
      final batch = _db.batch();
      final edgesRef = _db.collection(AppConstants.mapasCollection).doc('piso_$piso').collection('edges');
      
      for (final edge in edges) {
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
  Future<List<MapNodeModel>> loadNodes(int piso) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.mapasCollection)
          .doc('piso_$piso')
          .collection('nodes')
          .get();
      
      return snapshot.docs
          .map((doc) => MapNodeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error al cargar nodos del piso $piso: $e');
      rethrow;
    }
  }

  /// Carga todas las conexiones (edges) de un piso desde Firestore
  Future<List<EdgeModel>> loadEdges(int piso) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.mapasCollection)
          .doc('piso_$piso')
          .collection('edges')
          .get();
      
      return snapshot.docs
          .map((doc) => EdgeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error al cargar edges del piso $piso: $e');
      rethrow;
    }
  }

  /// Carga el grafo completo (nodos + edges) de un piso
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    final nodes = await loadNodes(piso);
    final edges = await loadEdges(piso);
    
    return {
      'nodes': nodes,
      'edges': edges,
    };
  }

  /// Busca el nodo de entrada principal de un piso
  Future<MapNodeModel?> findEntranceNode(int piso) async {
    final nodes = await loadNodes(piso);
    if (nodes.isEmpty) return null;
    
    // Buscar nodo con tipo "entrada" o que contenga "entrada" en el ID
    try {
      return nodes.firstWhere(
        (node) => node.tipo == 'entrada' || node.id.toLowerCase().contains('entrada'),
        orElse: () => nodes.first,
      );
    } catch (e) {
      return nodes.isNotEmpty ? nodes.first : null;
    }
  }

  /// Busca un nodo por ID
  Future<MapNodeModel?> findNodeById(int piso, String nodeId) async {
    try {
      final doc = await _db
          .collection(AppConstants.mapasCollection)
          .doc('piso_$piso')
          .collection('nodes')
          .doc(nodeId)
          .get();
      
      if (doc.exists) {
        return MapNodeModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error al buscar nodo $nodeId en piso $piso: $e');
      return null;
    }
  }
}

