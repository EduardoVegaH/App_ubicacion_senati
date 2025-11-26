import '../entities/map_node.dart';
import '../entities/map_floor.dart';
import '../repositories/navigation_repository.dart';
import 'a_star_algorithm.dart';

/// Excepción lanzada cuando no se encuentra una ruta
class RouteNotFoundException implements Exception {
  final String message;
  RouteNotFoundException(this.message);

  @override
  String toString() => 'RouteNotFoundException: $message';
}

/// Caso de uso para obtener la ruta entre dos nodos usando el algoritmo A*
/// 
/// Implementa el algoritmo A* en la capa domain sin dependencias externas
class GetRouteToRoomUseCase {
  final NavigationRepository repository;

  GetRouteToRoomUseCase(this.repository);

  /// Calcula la ruta desde un nodo origen hasta un nodo destino
  /// 
  /// [floor] El piso donde se busca la ruta
  /// [fromNodeId] ID del nodo de origen
  /// [toNodeId] ID del nodo de destino
  /// 
  /// Retorna una lista de MapNode que representa el camino encontrado
  /// Lanza [RouteNotFoundException] si no se encuentra una ruta
  Future<List<MapNode>> call({
    required int floor,
    required String fromNodeId,
    required String toNodeId,
  }) async {
    // Cargar el grafo del piso
    final mapFloor = await repository.getFloorGraph(floor);
    
    // Verificar que se cargaron datos
    if (mapFloor.nodes.isEmpty) {
      throw RouteNotFoundException(
        'No se encontraron nodos para el piso $floor. Verifica que los nodos estén inicializados en Firestore.',
      );
    }
    
    // Filtrar edges para asegurarse de que solo incluyan edges del piso correcto
    final validEdges = mapFloor.edges.where((e) => e.floor == floor).toList();
    if (validEdges.length != mapFloor.edges.length) {
      print('⚠️ ADVERTENCIA: Se encontraron ${mapFloor.edges.length - validEdges.length} edges con piso incorrecto');
    }
    
    // Crear un nuevo mapFloor con edges filtrados
    final filteredMapFloor = MapFloor(
      floor: floor,
      nodes: mapFloor.nodes,
      edges: validEdges,
    );

    // Validar que existan los nodos
    final fromNode = filteredMapFloor.nodes.firstWhere(
      (node) => node.id == fromNodeId,
      orElse: () => throw RouteNotFoundException(
        'Nodo origen no encontrado: $fromNodeId',
      ),
    );

    filteredMapFloor.nodes.firstWhere(
      (node) => node.id == toNodeId,
      orElse: () => throw RouteNotFoundException(
        'Nodo destino no encontrado: $toNodeId',
      ),
    );

    // Si el origen y destino son el mismo, retornar solo ese nodo
    if (fromNodeId == toNodeId) {
      return [fromNode];
    }

    // Ejecutar algoritmo A*
    print('🔍 Ejecutando A*: ${filteredMapFloor.nodes.length} nodos, ${filteredMapFloor.edges.length} edges');
    print('   Desde: $fromNodeId (${fromNode.x.toStringAsFixed(1)}, ${fromNode.y.toStringAsFixed(1)})');
    print('   Hasta: $toNodeId');
    
    // Verificar que hay edges conectados al nodo de inicio
    final edgesFromStart = filteredMapFloor.edges.where((e) => 
      e.fromId == fromNodeId || e.toId == fromNodeId
    ).toList();
    print('   Edges conectados al nodo de inicio: ${edgesFromStart.length}');
    if (edgesFromStart.isNotEmpty) {
      print('   Primeros edges: ${edgesFromStart.take(3).map((e) => '${e.fromId}->${e.toId}').join(", ")}');
    }
    
    final path = AStarAlgorithm.findPath(
      nodes: filteredMapFloor.nodes,
      edges: filteredMapFloor.edges,
      startId: fromNodeId,
      goalId: toNodeId,
    );

    if (path.isEmpty) {
      print('❌ A* no encontró ruta. Verificando conectividad...');
      // Verificar si hay algún camino posible
      final edgesToGoal = filteredMapFloor.edges.where((e) => 
        e.fromId == toNodeId || e.toId == toNodeId
      ).toList();
      final edgesFromStartForError = filteredMapFloor.edges.where((e) => 
        e.fromId == fromNodeId || e.toId == fromNodeId
      ).toList();
      
      print('   Edges conectados al nodo destino: ${edgesToGoal.length}');
      print('   Edges conectados al nodo origen: ${edgesFromStartForError.length}');
      print('   Total de edges en el piso: ${filteredMapFloor.edges.length}');
      
      // Si no hay edges en absoluto, sugerir inicialización
      if (filteredMapFloor.edges.isEmpty) {
        throw RouteNotFoundException(
          'No hay edges configurados para el piso $floor. '
          'Necesitas inicializar los edges usando GraphInitializer o configurarlos manualmente en Firestore.',
        );
      }
      
      // Si los nodos no tienen edges, son nodos aislados
      if (edgesFromStartForError.isEmpty) {
        throw RouteNotFoundException(
          'El nodo origen "$fromNodeId" no tiene conexiones (edges) en el piso $floor. '
          'Verifica que el nodo esté conectado a otros nodos.',
        );
      }
      
      if (edgesToGoal.isEmpty) {
        throw RouteNotFoundException(
          'El nodo destino "$toNodeId" no tiene conexiones (edges) en el piso $floor. '
          'Verifica que el nodo esté conectado a otros nodos.',
        );
      }
      
      // Si ambos tienen edges pero no hay ruta, el grafo está desconectado
      throw RouteNotFoundException(
        'No se encontró una ruta desde $fromNodeId hasta $toNodeId en el piso $floor. '
        'Los nodos existen pero no están conectados en el grafo. '
        'Verifica que haya un camino de edges entre estos nodos.',
      );
    }

    print('✅ Ruta encontrada con ${path.length} nodos');
    print('   Ruta: ${path.map((n) => n.id).join(" -> ")}');
    
    return path;
  }
}

