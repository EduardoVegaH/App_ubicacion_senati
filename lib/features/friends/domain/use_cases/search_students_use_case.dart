import '../entities/friend_entity.dart';
import '../repositories/friends_repository.dart';

/// Resultado de búsqueda con información de si es amigo
class SearchResult {
  final FriendEntity friend;
  final bool isFriend;

  SearchResult({
    required this.friend,
    required this.isFriend,
  });
}

/// Caso de uso compuesto para buscar estudiantes (por ID o nombre)
/// y verificar si son amigos
class SearchStudentsUseCase {
  final FriendsRepository _repository;

  SearchStudentsUseCase(this._repository);

  /// Buscar estudiantes por query (ID o nombre) y verificar si son amigos
  /// 
  /// Estrategia de búsqueda:
  /// 1. Primero intenta buscar por ID (búsqueda exacta)
  /// 2. Si no encuentra, busca por nombre (búsqueda parcial)
  /// 3. Para cada resultado, verifica si ya es amigo
  Future<List<SearchResult>> call(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // 1. Primero intentar buscar por ID (búsqueda exacta)
    final friendById = await _repository.searchStudentById(query);
    
    if (friendById != null) {
      // Verificar si es amigo
      final isFriend = await _repository.isFriend(friendById.uid);
      return [
        SearchResult(
          friend: friendById,
          isFriend: isFriend,
        ),
      ];
    }

    // 2. Si no se encuentra por ID, buscar por nombre (búsqueda parcial)
    final friendsByName = await _repository.searchStudentByName(query);
    
    if (friendsByName.isEmpty) {
      return [];
    }

    // 3. Para cada resultado, verificar si es amigo
    final results = <SearchResult>[];
    for (var friend in friendsByName) {
      final isFriend = await _repository.isFriend(friend.uid);
      results.add(
        SearchResult(
          friend: friend,
          isFriend: isFriend,
        ),
      );
    }

    return results;
  }
}

