import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../data/index.dart';
import '../../domain/index.dart';

/// Página de amigos (refactorizada)
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendsRemoteDataSource _dataSource;
  late final FriendsRepositoryImpl _repository;
  late final GetFriendsUseCase _getFriendsUseCase;
  late final SearchStudentUseCase _searchStudentUseCase;
  late final AddFriendUseCase _addFriendUseCase;
  
  final TextEditingController _searchController = TextEditingController();
  List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  bool _loading = true;
  FriendModel? _searchResult;
  final Map<String, bool> _showMap = {};
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _dataSource = FriendsRemoteDataSource();
    _repository = FriendsRepositoryImpl(_dataSource);
    _getFriendsUseCase = GetFriendsUseCase(_repository);
    _searchStudentUseCase = SearchStudentUseCase(_repository);
    _addFriendUseCase = AddFriendUseCase(_repository);
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _searchStudent() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
        _filteredFriends = _friends;
      });
      return;
    }

    setState(() => _searchResult = null);

    try {
      final friendEntity = await _searchStudentUseCase.call(query);
      
      if (friendEntity != null) {
        final friend = FriendModel(
          uid: friendEntity.uid,
          name: friendEntity.name,
          id: friendEntity.id,
          photoUrl: friendEntity.photoUrl,
          status: friendEntity.status,
          latitude: friendEntity.latitude,
          longitude: friendEntity.longitude,
          lastUpdate: friendEntity.lastUpdate,
        );
        setState(() {
          _searchResult = friend;
          _filteredFriends = [friend];
        });
      } else {
        setState(() {
          _searchResult = null;
          _filteredFriends = _friends.where((f) {
            return f.name.toLowerCase().contains(query.toLowerCase()) || f.id.contains(query);
          }).toList();
        });
        
        if (_filteredFriends.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('No se encontró ningún estudiante'), backgroundColor: AppStyles.warningColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e'), backgroundColor: AppStyles.errorColor),
        );
      }
    }
  }

  Future<void> _addFriend(FriendModel friend) async {
    final success = await _addFriendUseCase.call(friend.uid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Amigo agregado exitosamente'), backgroundColor: AppStyles.successColor),
      );
      _searchController.clear();
      setState(() {
        _searchResult = null;
        _filteredFriends = _friends;
      });
      _loadFriends();
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final success = await _repository.removeFriend(friendUid);
    if (success && mounted) {
      setState(() {
        _friends.removeWhere((f) => f.uid == friendUid);
        _filteredFriends.removeWhere((f) => f.uid == friendUid);
        _searchResult = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Amigo eliminado'), backgroundColor: AppStyles.successColor),
      );
      _loadFriends();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error al eliminar amigo'), backgroundColor: AppStyles.errorColor),
      );
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          return friend.name.toLowerCase().contains(query.toLowerCase()) || friend.id.contains(query);
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
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBar(
        title: const Text('Amigos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _hasSearchText = value.isNotEmpty);
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
                    style: TextStyle(color: Colors.grey[800], fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID o nombre',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search, color: AppStyles.primaryColor, size: isLargePhone ? 24 : (isTablet ? 26 : 22)),
                      suffixIcon: _hasSearchText ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _hasSearchText = false;
                            _searchResult = null;
                            _filteredFriends = _friends;
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: isLargePhone ? 20 : (isTablet ? 22 : 18)),
                      ) : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppStyles.primaryColor, width: 2)),
                      contentPadding: EdgeInsets.symmetric(horizontal: isLargePhone ? 20 : (isTablet ? 22 : 16), vertical: isLargePhone ? 16 : (isTablet ? 18 : 14)),
                    ),
                  ),
                ),
                if (_searchResult != null) ...[
                  const SizedBox(height: 16),
                  _buildSearchResultCard(_searchResult!, isLargePhone, isTablet),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No hay estudiantes registrados', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Busca estudiantes por su ID para ver su información', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : _buildFriendsList(isLargePhone, isTablet, padding),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(FriendModel friend, bool isLargePhone, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: isLargePhone ? 30 : (isTablet ? 32 : 28),
            backgroundColor: Colors.grey[300],
            backgroundImage: friend.photoUrl.isNotEmpty ? NetworkImage(friend.photoUrl) : null,
            child: friend.photoUrl.isEmpty ? Icon(Icons.person, size: isLargePhone ? 30 : 28) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: TextStyle(fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('ID: ${friend.id}', style: TextStyle(fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12), color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addFriend(friend),
            icon: const Icon(Icons.add_circle, color: Color(0xFF1B38E3), size: 32),
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
        Padding(
          padding: EdgeInsets.only(top: padding, bottom: isLargePhone ? 16 : (isTablet ? 18 : 14)),
          child: Text('Mis amigos', style: TextStyle(fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13), fontWeight: FontWeight.w600, color: Colors.grey[700])),
        ),
        ..._filteredFriends.map((friend) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFriendCard(friend, isLargePhone, isTablet),
        )),
      ],
    );
  }

  Widget _buildFriendCard(FriendModel friend, bool isLargePhone, bool isTablet) {
    final showMap = _showMap[friend.uid] ?? false;
    final statusColor = friend.isPresent ? Colors.green : Colors.red;
    final statusText = friend.isPresent ? 'Presente' : 'Ausente';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 18 : 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: isLargePhone ? 28 : (isTablet ? 30 : 26),
                        backgroundColor: Colors.grey[300],
                        backgroundImage: friend.photoUrl.isNotEmpty ? NetworkImage(friend.photoUrl) : null,
                        child: friend.photoUrl.isEmpty ? Icon(Icons.person, size: isLargePhone ? 28 : 26) : null,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                          child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friend.name, style: TextStyle(fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('ID: ${friend.id}', style: TextStyle(fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12), color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(friend.status, style: TextStyle(fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11), color: statusColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              if (friend.latitude != null && friend.longitude != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: isLargePhone ? 44 : (isTablet ? 48 : 40),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap[friend.uid] = !showMap),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B38E3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    icon: Icon(showMap ? Icons.arrow_upward : Icons.send),
                    label: Text(showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa', style: TextStyle(fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13))),
                  ),
                ),
                if (showMap) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0)), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF5F5F5)),
                    child: Padding(
                      padding: EdgeInsets.all(isLargePhone ? 12 : (isTablet ? 14 : 10)),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: isLargePhone ? 20 : (isTablet ? 22 : 18), color: const Color(0xFF2C2C2C)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(friend.name, style: TextStyle(fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13), fontWeight: FontWeight.bold, color: const Color(0xFF2C2C2C))),
                                Text('Lat: ${friend.latitude!.toStringAsFixed(6)}, Lon: ${friend.longitude!.toStringAsFixed(6)}', style: TextStyle(fontSize: isLargePhone ? 11 : (isTablet ? 12 : 10), color: const Color(0xFF757575))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
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
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                child: Icon(Icons.delete_outline, color: const Color(0xFF0D47A1), size: isLargePhone ? 20 : (isTablet ? 22 : 18)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

