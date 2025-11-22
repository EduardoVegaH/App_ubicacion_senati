import '../models/map_node.dart';

/// Utilidad para mapear salones a nodos cuando no hay asociación directa
/// Usa heurísticas para encontrar el nodo más apropiado
class SalonNodeMapper {
  /// Encuentra el nodo más apropiado para un salón dado
  /// 
  /// Estrategias:
  /// 1. Buscar por número del salón en el ID del nodo
  /// 2. Buscar nodos cercanos a la posición esperada del salón
  /// 3. Usar nodo central como fallback
  static MapNode? findNodeForSalon({
    required String salonId, // ej: "salon-A-604"
    required List<MapNode> nodes,
  }) {
    if (nodes.isEmpty) return null;
    
    // Extraer información del salón
    final salonNumber = salonId.replaceAll(RegExp(r'[^0-9]'), '');
    // Nota: La torre se puede usar en el futuro para mejorar la búsqueda
    
    // Estrategia 1: Buscar nodos que contengan el número del salón
    if (salonNumber.isNotEmpty) {
      // Buscar exacto primero
      final exactMatch = nodes.where(
        (n) => n.id.contains(salonNumber) ||
               (n.salonId != null && n.salonId!.contains(salonNumber)),
      ).toList();
      
      if (exactMatch.isNotEmpty) {
        return exactMatch.first;
      }
      
      // Buscar por últimos dígitos (ej: 604 -> buscar "04" o "4")
      if (salonNumber.length >= 2) {
        final lastTwo = salonNumber.substring(salonNumber.length - 2);
        final lastOne = salonNumber.substring(salonNumber.length - 1);
        
        for (final node in nodes) {
          if (node.id.contains(lastTwo) || 
              node.id.contains(lastOne) ||
              (node.salonId != null && 
               (node.salonId!.contains(lastTwo) || node.salonId!.contains(lastOne)))) {
            return node;
          }
        }
      }
    }
    
    // Estrategia 2: Si tenemos torre, buscar nodos en esa área
    // Por ahora, todas las torres están en el mismo mapa, así que esto es menos útil
    
    // Estrategia 3: Fallback - nodo más cercano al centro
    return _findCentralNode(nodes);
  }

  /// Encuentra el nodo más cercano al centro del mapa
  static MapNode _findCentralNode(List<MapNode> nodes) {
    if (nodes.isEmpty) throw ArgumentError('Lista de nodos vacía');
    
    // Calcular centro del mapa
    double sumX = 0, sumY = 0;
    for (final node in nodes) {
      sumX += node.x;
      sumY += node.y;
    }
    final centerX = sumX / nodes.length;
    final centerY = sumY / nodes.length;
    
    // Encontrar nodo más cercano al centro
    MapNode? nearest;
    double minDist = double.infinity;
    
    for (final node in nodes) {
      final dx = node.x - centerX;
      final dy = node.y - centerY;
      final dist = (dx * dx + dy * dy);
      if (dist < minDist) {
        minDist = dist;
        nearest = node;
      }
    }
    
    return nearest!;
  }
}

