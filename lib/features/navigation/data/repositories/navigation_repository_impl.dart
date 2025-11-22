import 'dart:math' as math;
import '../../domain/entities/map_node_entity.dart';
import '../../domain/entities/edge_entity.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../data_sources/navigation_remote_data_source.dart';
import '../models/map_node_model.dart';
import '../models/edge_model.dart';

/// Implementación del repositorio de navegación
class NavigationRepositoryImpl implements NavigationRepository {
  final NavigationRemoteDataSource _dataSource;
  
  NavigationRepositoryImpl(this._dataSource);
  
  @override
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    final graph = await _dataSource.loadGraph(piso);
    return {
      'nodes': (graph['nodes'] as List<MapNodeModel>).map((n) => n.toEntity()).toList(),
      'edges': (graph['edges'] as List<EdgeModel>).map((e) => e.toEntity()).toList(),
    };
  }
  
  @override
  Future<List<EdgeEntity>> findPath({
    required int piso,
    required String startNodeId,
    required String endNodeId,
  }) async {
    final graph = await _dataSource.loadGraph(piso);
    final nodes = graph['nodes'] as List<MapNodeModel>;
    final edges = graph['edges'] as List<EdgeModel>;
    
    final path = _dataSource.calculatePath(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );
    
    return path.map((e) => e.toEntity()).toList();
  }
  
  @override
  Future<MapNodeEntity?> findEntranceNode(int piso) async {
    final node = await _dataSource.findEntranceNode(piso);
    return node?.toEntity();
  }
  
  @override
  Future<MapNodeEntity?> findNearestElevatorNode(int piso) async {
    try {
      final nodes = await _dataSource.loadNodes(piso);
      if (nodes.isEmpty) return null;
      
      final elevatorPositions = [
        {'x': 1147.52, 'y': 563.907},
        {'x': 1066.52, 'y': 565.907},
        {'x': 987.517, 'y': 567.907},
        {'x': 1040.52, 'y': 754.907},
        {'x': 962.517, 'y': 758.907},
        {'x': 908.517, 'y': 572.571},
      ];
      
      MapNodeModel? nearestNode;
      double minDistance = double.infinity;
      
      for (final node in nodes) {
        for (final elevator in elevatorPositions) {
          final dx = node.x - elevator['x']!;
          final dy = node.y - elevator['y']!;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance < minDistance) {
            minDistance = distance;
            nearestNode = node;
          }
        }
      }
      
      return nearestNode?.toEntity();
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<MapNodeEntity?> findNodeBySalon({
    required int piso,
    required String salonId,
  }) async {
    final node = await _dataSource.findNodeBySalon(piso: piso, salonId: salonId);
    return node?.toEntity();
  }
}

