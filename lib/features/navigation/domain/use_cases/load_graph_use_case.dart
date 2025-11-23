import '../repositories/navigation_repository.dart';

/// Use case para cargar el grafo de un piso
class LoadGraphUseCase {
  final NavigationRepository _repository;

  LoadGraphUseCase(this._repository);

  /// Cargar grafo completo (nodos y edges) de un piso
  Future<Map<String, dynamic>> call(int piso) async {
    return await _repository.loadGraph(piso);
  }
}

