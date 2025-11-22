import 'package:flutter/material.dart';
import '../../models/friend_model.dart';
import '../../services/friends_service.dart';
import '../widgets/tower_map_viewer.dart';
import '../Navigation/navigation_map_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  List<Friend> _friends = [];
  List<Friend> _filteredFriends = [];
  bool _loading = true;
  Friend? _searchResult;
  final Map<String, bool> _showMap = {};
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
    });

    try {
      final friends = await _friendsService.getFriends();
      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar amigos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchStudent() async {
    final query = _searchController.text.trim();
    
    // Si está vacío, mostrar todos los amigos
    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
        _filteredFriends = _friends;
      });
      return;
    }

    // Primero intentar buscar por ID exacto
    setState(() {
      _searchResult = null;
    });

    try {
      final friend = await _friendsService.searchStudentById(query);
      
      if (friend != null) {
        // Si se encontró por ID, mostrar solo ese resultado
        setState(() {
          _searchResult = friend;
          _filteredFriends = [friend];
        });
      } else {
        // Si no se encontró por ID, filtrar la lista por nombre o ID
        setState(() {
          _searchResult = null;
          _filteredFriends = _friends.where((f) {
            return f.name.toLowerCase().contains(query.toLowerCase()) ||
                f.id.contains(query);
          }).toList();
        });
        
        if (_filteredFriends.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontró ningún estudiante'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addFriend(Friend friend) async {
    final success = await _friendsService.addFriend(friend.uid);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amigo agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiar búsqueda y recargar lista
        _searchController.clear();
        setState(() {
          _searchResult = null;
          _filteredFriends = _friends;
        });
        _loadFriends();
      }
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    // Eliminar directamente sin confirmación
    final success = await _friendsService.removeFriend(friendUid);
    if (success) {
      if (mounted) {
        // Actualizar la lista localmente primero para respuesta inmediata
        setState(() {
          _friends.removeWhere((f) => f.uid == friendUid);
          _filteredFriends.removeWhere((f) => f.uid == friendUid);
          _searchResult = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amigo eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar para asegurar sincronización
        _loadFriends();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar amigo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          return friend.name.toLowerCase().contains(query.toLowerCase()) ||
              friend.id.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
    final padding = isLargePhone ? 20.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Amigos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B38E3),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(padding),
            color: const Color(0xFF1B38E3),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Filtrar en tiempo real mientras se escribe
                      setState(() {
                        _hasSearchText = value.isNotEmpty;
                      });
                      if (value.isEmpty) {
                        setState(() {
                          _searchResult = null;
                          _filteredFriends = _friends;
                        });
                      } else {
                        _filterFriends(value);
                      }
                    },
                    onSubmitted: (_) => _searchStudent(),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID o nombre',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFF1B38E3),
                        size: isLargePhone ? 24 : (isTablet ? 26 : 22),
                      ),
                      suffixIcon: _hasSearchText
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _hasSearchText = false;
                                  _searchResult = null;
                                  _filteredFriends = _friends;
                                });
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[400],
                                size: isLargePhone ? 20 : (isTablet ? 22 : 18),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF1B38E3),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isLargePhone ? 20 : (isTablet ? 22 : 16),
                        vertical: isLargePhone ? 16 : (isTablet ? 18 : 14),
                      ),
                    ),
                  ),
                ),
                // Resultado de búsqueda
                if (_searchResult != null) ...[
                  const SizedBox(height: 16),
                  _buildSearchResultCard(_searchResult!, isLargePhone, isTablet),
                ],
              ],
            ),
          ),

          // Lista de amigos
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay estudiantes registrados',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Busca estudiantes por su ID para ver su información',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: _buildFriendsList(isLargePhone, isTablet, padding),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Friend friend, bool isLargePhone, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Foto de perfil
          CircleAvatar(
            radius: isLargePhone ? 30 : (isTablet ? 32 : 28),
            backgroundColor: Colors.grey[300],
            backgroundImage: friend.photoUrl.isNotEmpty
                ? NetworkImage(friend.photoUrl)
                : null,
            child: friend.photoUrl.isEmpty
                ? Icon(Icons.person, size: isLargePhone ? 30 : 28)
                : null,
          ),
          const SizedBox(width: 12),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: TextStyle(
                    fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${friend.id}',
                  style: TextStyle(
                    fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Icono de agregar
          IconButton(
            onPressed: () {
              _addFriend(friend);
            },
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF1B38E3),
              size: 32,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(bool isLargePhone, bool isTablet, double padding) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      children: [
        // Título "Mis amigos"
        Padding(
          padding: EdgeInsets.only(
            top: padding,
            bottom: isLargePhone ? 16 : (isTablet ? 18 : 14),
          ),
          child: Text(
            'Mis amigos',
            style: TextStyle(
              fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        // Lista de amigos
        ..._filteredFriends.map((friend) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFriendCard(friend, isLargePhone, isTablet),
            )),
      ],
    );
  }

  Widget _buildFriendCard(Friend friend, bool isLargePhone, bool isTablet) {
    final showMap = _showMap[friend.uid] ?? false;
    final statusColor = friend.isPresent ? Colors.green : Colors.red;
    final statusText = friend.isPresent ? 'Presente' : 'Ausente';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Foto de perfil
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: isLargePhone ? 28 : (isTablet ? 30 : 26),
                        backgroundColor: Colors.grey[300],
                        backgroundImage: friend.photoUrl.isNotEmpty
                            ? NetworkImage(friend.photoUrl)
                            : null,
                        child: friend.photoUrl.isEmpty
                            ? Icon(Icons.person, size: isLargePhone ? 28 : 26)
                            : null,
                      ),
                      // Badge de estado
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: TextStyle(
                            fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${friend.id}',
                          style: TextStyle(
                            fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          friend.status,
                          style: TextStyle(
                            fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Botón ver ubicación
              if (friend.latitude != null && friend.longitude != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: isLargePhone ? 44 : (isTablet ? 48 : 40),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMap[friend.uid] = !showMap;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B38E3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(showMap ? Icons.arrow_upward : Icons.send),
                    label: Text(
                      showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa',
                      style: TextStyle(
                        fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                      ),
                    ),
                  ),
                ),
                // Mapa (si está visible)
                if (showMap) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF5F5F5),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(isLargePhone ? 12 : (isTablet ? 14 : 10)),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: isLargePhone ? 20 : (isTablet ? 22 : 18),
                                color: const Color(0xFF2C2C2C),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend.name,
                                      style: TextStyle(
                                        fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    Text(
                                      'Lat: ${friend.latitude!.toStringAsFixed(6)}, Lon: ${friend.longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: isLargePhone ? 11 : (isTablet ? 12 : 10),
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TowerMapViewer(
                          height: isLargePhone ? 200 : (isTablet ? 250 : 180),
                          showControls: true,
                        ),
                        Padding(
                          padding: EdgeInsets.all(isLargePhone ? 12 : (isTablet ? 14 : 10)),
                          child: SizedBox(
                            width: double.infinity,
                            height: isLargePhone ? 44 : (isTablet ? 48 : 40),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => NavigationMapScreen(
                                      locationName: friend.name,
                                      locationDetail: 'Lat: ${friend.latitude!.toStringAsFixed(6)}, Lon: ${friend.longitude!.toStringAsFixed(6)}',
                                      initialView: 'interior', // Por defecto mostrar vista interior para navegación
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D79FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.send),
                              label: Text(
                                'Navegar Ahora (Tiempo Real)',
                                style: TextStyle(
                                  fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      // Icono de basura en la esquina superior derecha
      Positioned(
        top: -8,
        right: -8,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _removeFriend(friend.uid),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.delete_outline,
                color: const Color(0xFF0D47A1), // Azul oscuro
                size: isLargePhone ? 20 : (isTablet ? 22 : 18),
              ),
            ),
          ),
        ),
      ),
    ],
    );
  }
}

