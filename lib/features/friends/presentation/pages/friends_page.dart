import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/search_bar/search_bar.dart' as custom;
import '../../../../core/widgets/empty_states/index.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/index.dart';
import '../../data/models/friend_model.dart';
import '../widgets/friend_card.dart';
import '../widgets/search_result_card.dart';

/// Página de amigos (refactorizada)
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final GetFriendsUseCase _getFriendsUseCase;
  late final SearchStudentsUseCase _searchStudentsUseCase;
  late final AddFriendUseCase _addFriendUseCase;
  late final RemoveFriendUseCase _removeFriendUseCase;
  
  final TextEditingController _searchController = TextEditingController();
  List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  bool _loading = true;
  List<FriendModel> _searchResults = [];
  final Map<String, bool> _isFriendMap = {}; // Mapa para verificar si es amigo
  final Map<String, bool> _showMap = {};
  Timer? _searchDebounceTimer; // Timer para debounce de búsqueda

  @override
  void initState() {
    super.initState();
    _getFriendsUseCase = sl<GetFriendsUseCase>();
    _searchStudentsUseCase = sl<SearchStudentsUseCase>();
    _addFriendUseCase = sl<AddFriendUseCase>();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _loading = true);
    try {
      final friends = await _getFriendsUseCase.call();
      setState(() {
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
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar amigos: $e'), backgroundColor: AppStyles.errorColor),
        );
      }
    }
  }

  /// Búsqueda cuando se presiona Enter (sin debounce)
  Future<void> _searchStudent() async {
    _searchDebounceTimer?.cancel(); // Cancelar búsqueda pendiente
    await _performSearch(_searchController.text.trim());
  }

  Future<void> _addFriend(FriendModel friend) async {
    final success = await _addFriendUseCase.call(friend.uid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Amigo agregado exitosamente'),
          backgroundColor: AppStyles.successColor,
        ),
      );
      // Actualizar estado: ahora es amigo
      setState(() {
        _isFriendMap[friend.uid] = true;
        // Si está en los resultados de búsqueda, agregarlo a la lista filtrada
        if (_searchResults.any((f) => f.uid == friend.uid)) {
          if (!_filteredFriends.any((f) => f.uid == friend.uid)) {
            _filteredFriends.add(friend);
          }
        }
      });
      _loadFriends(); // Recargar lista completa
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al agregar amigo'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final success = await _removeFriendUseCase.call(friendUid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Amigo eliminado'),
          backgroundColor: AppStyles.successColor,
        ),
      );
      // Actualizar estado: ya no es amigo
      setState(() {
        _isFriendMap[friendUid] = false;
        _friends.removeWhere((f) => f.uid == friendUid);
        _filteredFriends.removeWhere((f) => f.uid == friendUid);
        // Si está en los resultados de búsqueda, mantenerlo ahí pero marcado como no amigo
      });
      _loadFriends(); // Recargar lista completa
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al eliminar amigo'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  /// Buscar en Firebase mientras el usuario escribe (con debounce)
  void _searchWhileTyping(String query) {
    // Cancelar búsqueda anterior si existe
    _searchDebounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isFriendMap.clear();
        _filteredFriends = _friends;
      });
      return;
    }

    // Esperar 500ms después de que el usuario deje de escribir
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Realizar búsqueda en Firebase (delega la lógica al use case)
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isFriendMap.clear();
        _filteredFriends = _friends;
      });
      return;
    }

    setState(() {
      _searchResults = [];
      _isFriendMap.clear();
    });

    try {
      // Delegar toda la lógica de búsqueda al use case
      final searchResults = await _searchStudentsUseCase.call(query);
      
      if (searchResults.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se encontró ningún estudiante'),
              backgroundColor: AppStyles.warningColor,
            ),
          );
        }
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
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
    final padding = isLargePhone ? 20.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Amigos',
          style: AppTextStyles.titleMedium(false, false, AppStyles.textOnDark).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppStyles.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            color: AppStyles.primaryColor,
            child: Column(
              children: [
                custom.CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar por ID o nombre',
                    onChanged: (value) {
                      // Buscar en Firebase mientras escribe (con debounce)
                      _searchWhileTyping(value);
                    },
                    onSubmitted: _searchStudent,
                    onClear: () {
                      setState(() {
                        _searchResults = [];
                        _isFriendMap.clear();
                        _filteredFriends = _friends;
                      });
                    },
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._searchResults.map((friend) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SearchResultCard(
                      friend: friend,
                      isFriend: _isFriendMap[friend.uid] ?? false,
                      onAdd: () => _addFriend(friend),
                      onRemove: () => _removeFriend(friend.uid),
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                  )),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty && _searchResults.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        message: 'No hay estudiantes registrados',
                        secondaryMessage: 'Busca estudiantes por su ID o nombre para agregarlos',
                      )
                    : _buildFriendsList(isLargePhone, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(bool isLargePhone, bool isTablet) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 20.0 : (isTablet ? 24.0 : 16.0),
      ),
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: isLargePhone ? 20.0 : (isTablet ? 24.0 : 16.0),
            bottom: isLargePhone ? 16 : (isTablet ? 18 : 14),
          ),
          child: Text(
            'Mis amigos',
            style: AppTextStyles.bodySmall(isLargePhone, isTablet, AppStyles.greyDark).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Si hay búsqueda activa, no mostrar la lista de amigos aquí
        if (_searchResults.isEmpty)
          ..._friends.map((friend) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FriendCard(
              friend: friend,
              showMap: _showMap[friend.uid] ?? false,
              onToggleMap: () => setState(() => _showMap[friend.uid] = !(_showMap[friend.uid] ?? false)),
              onDelete: () => _removeFriend(friend.uid),
              isLargePhone: isLargePhone,
              isTablet: isTablet,
            ),
          )),
      ],
    );
  }

}

