import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/index.dart';
import '../../data/models/friend_model.dart';

/// Controller para manejar el estado y lógica de presentación de amigos
class FriendsController extends ChangeNotifier {
  // Use cases
  final GetFriendsUseCase _getFriendsUseCase;
  final SearchStudentsUseCase _searchStudentsUseCase;
  final AddFriendUseCase _addFriendUseCase;
  final RemoveFriendUseCase _removeFriendUseCase;

  // Estado
  List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  bool _loading = true;
  String? _error;
  List<FriendModel> _searchResults = [];
  final Map<String, bool> _isFriendMap = {}; // Mapa para verificar si es amigo
  final Map<String, bool> _showMap = {};
  
  // Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // Getters
  List<FriendModel> get friends => _friends;
  List<FriendModel> get filteredFriends => _filteredFriends;
  bool get loading => _loading;
  String? get error => _error;
  List<FriendModel> get searchResults => _searchResults;
  bool isFriend(String uid) => _isFriendMap[uid] ?? false;
  bool showMap(String uid) => _showMap[uid] ?? false;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasFriends => _friends.isNotEmpty;

  FriendsController({
    required GetFriendsUseCase getFriendsUseCase,
    required SearchStudentsUseCase searchStudentsUseCase,
    required AddFriendUseCase addFriendUseCase,
    required RemoveFriendUseCase removeFriendUseCase,
  })  : _getFriendsUseCase = getFriendsUseCase,
        _searchStudentsUseCase = searchStudentsUseCase,
        _addFriendUseCase = addFriendUseCase,
        _removeFriendUseCase = removeFriendUseCase;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Cargar lista de amigos
  Future<void> loadFriends() async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final friends = await _getFriendsUseCase.call();
      _friends = friends.map((e) => FriendModel(
        uid: e.uid,
        name: e.name,
        id: e.id,
        photoUrl: e.photoUrl,
        status: e.status,
        latitude: e.latitude,
        longitude: e.longitude,
        lastUpdate: e.lastUpdate,
      )).toList();
      
      _filteredFriends = _friends;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar amigos: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Buscar estudiantes mientras el usuario escribe (con debounce)
  void searchWhileTyping(String query) {
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    // Esperar 500ms después de que el usuario deje de escribir
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      performSearch(query);
    });
  }

  /// Realizar búsqueda inmediata (sin debounce)
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }

    _setSearching();
    notifyListeners();

    try {
      final searchResults = await _searchStudentsUseCase.call(query);
      
      if (searchResults.isEmpty) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      // Convertir resultados del use case a modelos para la UI
      final results = <FriendModel>[];
      for (var searchResult in searchResults) {
        final friend = FriendModel(
          uid: searchResult.friend.uid,
          name: searchResult.friend.name,
          id: searchResult.friend.id,
          photoUrl: searchResult.friend.photoUrl,
          status: searchResult.friend.status,
          latitude: searchResult.friend.latitude,
          longitude: searchResult.friend.longitude,
          lastUpdate: searchResult.friend.lastUpdate,
        );
        results.add(friend);
        _isFriendMap[friend.uid] = searchResult.isFriend;
      }
      
      _searchResults = results;
      notifyListeners();
    } catch (e) {
      _error = 'Error al buscar: $e';
      _searchResults = [];
      notifyListeners();
    }
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _clearSearch();
    notifyListeners();
  }

  /// Agregar amigo
  Future<bool> addFriend(FriendModel friend) async {
    try {
      final success = await _addFriendUseCase.call(friend.uid);
      if (success) {
        // Actualizar estado: ahora es amigo
        _isFriendMap[friend.uid] = true;
        
        // Si está en los resultados de búsqueda, agregarlo a la lista filtrada
        if (_searchResults.any((f) => f.uid == friend.uid)) {
          if (!_filteredFriends.any((f) => f.uid == friend.uid)) {
            _filteredFriends.add(friend);
          }
        }
        
        // Recargar lista completa
        await loadFriends();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al agregar amigo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar amigo con actualización optimista
  Future<bool> removeFriend(String friendUid) async {
    // Actualización optimista: eliminar de la vista inmediatamente
    _removeFriendFromLists(friendUid);
    notifyListeners();

    try {
      // Eliminar en Firebase
      final success = await _removeFriendUseCase.call(friendUid);
      
      if (success) {
        // Recargar lista completa para asegurar sincronización
        await loadFriends();
        notifyListeners();
        return true;
      } else {
        // Si falló, recargar para restaurar el estado correcto
        await loadFriends();
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al eliminar amigo: $e';
      // Recargar para restaurar el estado correcto
      await loadFriends();
      notifyListeners();
      return false;
    }
  }

  /// Toggle mostrar/ocultar mapa para un amigo
  void toggleShowMap(String friendUid) {
    _showMap[friendUid] = !(_showMap[friendUid] ?? false);
    notifyListeners();
  }

  // ==================== MÉTODOS PRIVADOS ====================

  void _setLoading(bool value) {
    _loading = value;
    if (!value) {
      _error = null;
    }
  }

  void _setSearching() {
    _searchResults = [];
    _isFriendMap.clear();
  }

  void _clearSearch() {
    _searchResults = [];
    _isFriendMap.clear();
    _filteredFriends = _friends;
  }

  void _removeFriendFromLists(String friendUid) {
    _isFriendMap[friendUid] = false;
    _friends.removeWhere((f) => f.uid == friendUid);
    _filteredFriends.removeWhere((f) => f.uid == friendUid);
    
    // Si está en los resultados de búsqueda, actualizar el estado
    final index = _searchResults.indexWhere((f) => f.uid == friendUid);
    if (index != -1) {
      _isFriendMap[friendUid] = false;
    }
  }
}
