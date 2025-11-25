import '../entities/map_node.dart';
import '../repositories/navigation_repository.dart';

/// Use case para encontrar el nodo más cercano a los ascensores
/// 
/// Los ascensores son puntos de entrada comunes en el piso 2
class FindNearestElevatorNodeUseCase {
  final NavigationRepository repository;

  FindNearestElevatorNodeUseCase(this.repository);

  /// Encuentra el nodo más cercano a los ascensores en un piso
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna el MapNode más cercano a los ascensores, o null si no hay nodos
  Future<MapNode?> call(int floor) async {
    final nodes = await repository.getNodesForFloor(floor);
    if (nodes.isEmpty) return null;

    // Coordenadas aproximadas de los ascensores en el piso 2
    // Basadas en el SVG: ASEN#01 a ASEN#06
    // Estos están en el área central del piso 2
    final elevatorPositions = [
      {'x': 1167.84, 'y': 593.157}, // ASEN#01
      {'x': 1088.85, 'y': 596.755}, // ASEN#04
      {'x': 1010.86, 'y': 599.093}, // ASEN#05
      {'x': 930.864, 'y': 599.995}, // ASEN#06
      {'x': 984.0, 'y': 768.157}, // ASEN#03
      {'x': 1068.0, 'y': 765.157}, // ASEN#02
    ];

    MapNode? nearestNode;
    double minDistance = double.infinity;

    // Buscar el nodo más cercano a cualquiera de los ascensores
    for (final node in nodes) {
      for (final elevator in elevatorPositions) {
        final dx = node.x - elevator['x']!;
        final dy = node.y - elevator['y']!;
        final distance = (dx * dx + dy * dy); // Distancia euclidiana al cuadrado (sin sqrt para eficiencia)

        if (distance < minDistance) {
          minDistance = distance;
          nearestNode = node;
        }
      }
    }

    return nearestNode;
  }
}

