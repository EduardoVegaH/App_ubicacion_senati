import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/entities/map_edge.dart';
import '../../domain/entities/map_floor.dart';
import '../models/map_node_model.dart';
import '../models/map_edge_model.dart';

/// Fuente de datos remota para navegación usando Firestore
class FirestoreNavigationDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda el grafo completo de un piso en Firestore
  /// 
  /// Estructura en Firestore:
  /// - /mapas/piso_{floor}/nodes/{nodeId}
  /// - /mapas/piso_{floor}/edges/{fromId_toId}
  Future<void> saveFloorGraph(MapFloor floor) async {
    final batch = _db.batch();

    final nodesCollection = _db
        .collection('mapas')
        .doc('piso_${floor.floor}')
        .collection('nodes');

    final edgesCollection = _db
        .collection('mapas')
        .doc('piso_${floor.floor}')
        .collection('edges');

    // Guardar nodos
    for (final node in floor.nodes) {
      final nodeModel = MapNodeModel.fromEntity(node);
      final nodeRef = nodesCollection.doc(node.id);
      batch.set(nodeRef, nodeModel.toFirestore());
    }

    // Guardar edges
    for (final edge in floor.edges) {
      final edgeModel = MapEdgeModel.fromEntity(edge);
      // Usar formato "fromId_toId" como ID del documento
      final edgeId = '${edge.fromId}_${edge.toId}';
      final edgeRef = edgesCollection.doc(edgeId);
      batch.set(edgeRef, edgeModel.toFirestore());
    }

    await batch.commit();
  }

  /// Obtiene el grafo completo de un piso desde Firestore
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna un MapFloor con todos los nodos y edges del piso
  Future<MapFloor> getFloorGraph(int floor) async {
    final nodesCollection = _db
        .collection('mapas')
        .doc('piso_$floor')
        .collection('nodes');

    final edgesCollection = _db
        .collection('mapas')
        .doc('piso_$floor')
        .collection('edges');

    // Obtener nodos
    final nodesSnapshot = await nodesCollection.get();
    final nodes = nodesSnapshot.docs
        .map((doc) => MapNodeModel.fromFirestore(doc).toEntity())
        .toList();

    // Obtener edges
    final edgesSnapshot = await edgesCollection.get();
    final edges = edgesSnapshot.docs
        .map((doc) => MapEdgeModel.fromFirestore(doc).toEntity())
        .toList();

    return MapFloor(
      floor: floor,
      nodes: nodes,
      edges: edges,
    );
  }

  /// Obtiene todos los nodos de un piso específico
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna una lista de MapNode del piso
  Future<List<MapNode>> getNodesForFloor(int floor) async {
    final nodesCollection = _db
        .collection('mapas')
        .doc('piso_$floor')
        .collection('nodes');

    final nodesSnapshot = await nodesCollection.get();
    return nodesSnapshot.docs
        .map((doc) => MapNodeModel.fromFirestore(doc).toEntity())
        .toList();
  }

  /// Obtiene todos los edges de un piso específico
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna una lista de MapEdge del piso
  Future<List<MapEdge>> getEdgesForFloor(int floor) async {
    final edgesCollection = _db
        .collection('mapas')
        .doc('piso_$floor')
        .collection('edges');

    final edgesSnapshot = await edgesCollection.get();
    return edgesSnapshot.docs
        .map((doc) => MapEdgeModel.fromFirestore(doc).toEntity())
        .toList();
  }
}

