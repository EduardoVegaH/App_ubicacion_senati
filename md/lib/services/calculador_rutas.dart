import '../models/nodo_mapa.dart';
import 'dart:math' as math;

/// Clase que calcula rutas usando el algoritmo de Dijkstra
/// Encuentra el camino más corto entre dos nodos en un grafo
class CalculadorRutas {
  /// Calcula la ruta más corta entre dos nodos usando el algoritmo de Dijkstra
  /// 
  /// [idOrigen] - ID del nodo de inicio
  /// [idDestino] - ID del nodo de destino
  /// [nodos] - Lista de todos los nodos del mapa
  /// 
  /// Retorna una lista de nodos que representa el camino más corto.
  /// Si no hay camino, retorna una lista vacía.
  static List<NodoMapa> calcularRuta(
    String idOrigen,
    String idDestino,
    List<NodoMapa> nodos,
  ) {
    // Validar que existan los nodos origen y destino
    final nodoOrigen = NodoMapa.buscarPorId(nodos, idOrigen);
    final nodoDestino = NodoMapa.buscarPorId(nodos, idDestino);

    if (nodoOrigen == null) {
      throw ArgumentError('Nodo origen "$idOrigen" no encontrado');
    }

    if (nodoDestino == null) {
      throw ArgumentError('Nodo destino "$idDestino" no encontrado');
    }

    // Si origen y destino son el mismo, retornar solo ese nodo
    if (idOrigen == idDestino) {
      return [nodoOrigen];
    }

    // Crear un mapa para acceso rápido a nodos por ID
    final mapaNodos = <String, NodoMapa>{};
    for (final nodo in nodos) {
      mapaNodos[nodo.id] = nodo;
    }

    // Estructuras para el algoritmo de Dijkstra
    final distancias = <String, double>{};
    final anteriores = <String, String?>{};
    final visitados = <String>{};
    final colaPrioridad = <_NodoDistancia>[];

    // Inicializar distancias: todas infinitas excepto el origen (0)
    for (final nodo in nodos) {
      distancias[nodo.id] = double.infinity;
      anteriores[nodo.id] = null;
    }
    distancias[idOrigen] = 0.0;

    // Agregar el nodo origen a la cola de prioridad
    colaPrioridad.add(_NodoDistancia(idOrigen, 0.0));

    // Algoritmo de Dijkstra
    while (colaPrioridad.isNotEmpty) {
      // Obtener el nodo con menor distancia no visitado
      colaPrioridad.sort((a, b) => a.distancia.compareTo(b.distancia));
      final actual = colaPrioridad.removeAt(0);

      // Si ya fue visitado, continuar
      if (visitados.contains(actual.id)) {
        continue;
      }

      // Marcar como visitado
      visitados.add(actual.id);

      // Si llegamos al destino, podemos terminar
      if (actual.id == idDestino) {
        break;
      }

      // Obtener el nodo actual
      final nodoActual = mapaNodos[actual.id];
      if (nodoActual == null) continue;

      // Explorar todos los vecinos (conexiones)
      for (final idVecino in nodoActual.conexiones) {
        // Si el vecino ya fue visitado, saltarlo
        if (visitados.contains(idVecino)) {
          continue;
        }

        // Obtener el nodo vecino
        final nodoVecino = mapaNodos[idVecino];
        if (nodoVecino == null) continue;

        // Calcular la distancia al vecino (distancia euclidiana)
        final distancia = _calcularDistancia(nodoActual, nodoVecino);
        final distanciaTotal = distancias[actual.id]! + distancia;

        // Si encontramos un camino más corto, actualizar
        if (distanciaTotal < distancias[idVecino]!) {
          distancias[idVecino] = distanciaTotal;
          anteriores[idVecino] = actual.id;

          // Agregar a la cola de prioridad
          colaPrioridad.add(_NodoDistancia(idVecino, distanciaTotal));
        }
      }
    }

    // Reconstruir el camino desde el destino hasta el origen
    final ruta = <NodoMapa>[];
    String? nodoActualId = idDestino;

    while (nodoActualId != null) {
      final nodo = mapaNodos[nodoActualId];
      if (nodo != null) {
        ruta.insert(0, nodo); // Insertar al inicio para mantener el orden
      }
      nodoActualId = anteriores[nodoActualId];
    }

    // Si no hay camino (el destino no fue alcanzado), retornar lista vacía
    if (ruta.isEmpty || ruta.first.id != idOrigen) {
      return [];
    }

    return ruta;
  }

  /// Calcula la distancia euclidiana entre dos nodos
  static double _calcularDistancia(NodoMapa nodo1, NodoMapa nodo2) {
    final dx = nodo1.x - nodo2.x;
    final dy = nodo1.y - nodo2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calcula la distancia total de una ruta
  static double calcularDistanciaRuta(List<NodoMapa> ruta) {
    if (ruta.length < 2) return 0.0;

    double distanciaTotal = 0.0;
    for (int i = 0; i < ruta.length - 1; i++) {
      distanciaTotal += _calcularDistancia(ruta[i], ruta[i + 1]);
    }
    return distanciaTotal;
  }

  /// Verifica si existe un camino entre dos nodos
  static bool existeCamino(
    String idOrigen,
    String idDestino,
    List<NodoMapa> nodos,
  ) {
    try {
      final ruta = calcularRuta(idOrigen, idDestino, nodos);
      return ruta.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene todos los nodos alcanzables desde un nodo origen
  static List<NodoMapa> obtenerNodosAlcanzables(
    String idOrigen,
    List<NodoMapa> nodos,
  ) {
    final nodoOrigen = NodoMapa.buscarPorId(nodos, idOrigen);
    if (nodoOrigen == null) return [];

    final alcanzables = <String>{idOrigen};
    final cola = <String>[idOrigen];

    final mapaNodos = <String, NodoMapa>{};
    for (final nodo in nodos) {
      mapaNodos[nodo.id] = nodo;
    }

    // BFS para encontrar todos los nodos alcanzables
    while (cola.isNotEmpty) {
      final actualId = cola.removeAt(0);
      final nodoActual = mapaNodos[actualId];
      if (nodoActual == null) continue;

      for (final idVecino in nodoActual.conexiones) {
        if (!alcanzables.contains(idVecino)) {
          alcanzables.add(idVecino);
          cola.add(idVecino);
        }
      }
    }

    return alcanzables.map((id) => mapaNodos[id]!).toList();
  }
}

/// Clase auxiliar para la cola de prioridad en Dijkstra
class _NodoDistancia {
  final String id;
  final double distancia;

  _NodoDistancia(this.id, this.distancia);
}

