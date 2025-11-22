import '../models/map_node_model.dart';
import '../models/edge_model.dart';
import '../services/pathfinding_service.dart';
import '../services/graph_storage_service.dart';

/// Fuente de datos remota para navegación
class NavigationRemoteDataSource {
  final GraphStorageService _storageService = GraphStorageService();

  /// Cargar grafo completo de un piso
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    return await _storageService.loadGraph(piso);
  }

  /// Cargar solo nodos
  Future<List<MapNodeModel>> loadNodes(int piso) async {
    return await _storageService.loadNodes(piso);
  }

  /// Encontrar nodo de entrada
  Future<MapNodeModel?> findEntranceNode(int piso) async {
    return await _storageService.findEntranceNode(piso);
  }

  /// Encontrar nodo por salón
  Future<MapNodeModel?> findNodeBySalon({
    required int piso,
    required String salonId,
  }) async {
    final nodes = await loadNodes(piso);
    
    // Normalizar salonId
    String normalizedSalonId = salonId.toLowerCase().trim();
    if (normalizedSalonId.startsWith('salon-')) {
      normalizedSalonId = normalizedSalonId.substring(6);
    }
    
    try {
      return nodes.firstWhere(
        (node) => 
          node.salonId?.toLowerCase() == normalizedSalonId ||
          node.salonId?.toLowerCase().contains(normalizedSalonId) == true ||
          node.id.toLowerCase().contains(normalizedSalonId),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calcular ruta usando A*
  List<EdgeModel> calculatePath({
    required String startNodeId,
    required String endNodeId,
    required List<MapNodeModel> nodes,
    required List<EdgeModel> edges,
  }) {
    return PathfindingService.findPathAStar(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );
  }
}

