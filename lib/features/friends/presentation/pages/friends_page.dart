import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/search_bar/search_bar.dart' as custom;
import '../../../../core/widgets/empty_states/index.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/friends_controller.dart';
import '../widgets/friend_card.dart';
import '../widgets/search_result_card.dart';

/// Página de amigos (refactorizada con controller)
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late final FriendsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = sl<FriendsController>();
    _controller.addListener(_onControllerChanged);
    _controller.loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      
      // Mostrar mensajes de error si existen
      if (_controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.error!),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleAddFriend(friend) async {
    final success = await _controller.addFriend(friend);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Amigo agregado exitosamente'),
          backgroundColor: AppStyles.successColor,
        ),
      );
    } else if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al agregar amigo'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  Future<void> _handleRemoveFriend(String friendUid) async {
    final success = await _controller.removeFriend(friendUid);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Amigo eliminado'),
          backgroundColor: AppStyles.successColor,
        ),
      );
    } else if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al eliminar amigo'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }

  void _handleSearchSubmitted() {
    _controller.performSearch(_searchController.text.trim());
  }

  void _handleSearchChanged(String value) {
    _controller.searchWhileTyping(value);
  }

  void _handleSearchClear() {
    _searchController.clear();
    _controller.clearSearch();
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
                  onChanged: _handleSearchChanged,
                  onSubmitted: _handleSearchSubmitted,
                  onClear: _handleSearchClear,
                ),
                if (_controller.hasSearchResults) ...[
                  const SizedBox(height: 16),
                  ..._controller.searchResults.map((friend) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SearchResultCard(
                      friend: friend,
                      isFriend: _controller.isFriend(friend.uid),
                      onAdd: () => _handleAddFriend(friend),
                      onRemove: () => _handleRemoveFriend(friend.uid),
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                  )),
                ],
              ],
            ),
          ),
          Expanded(
            child: _controller.loading
                ? const Center(child: CircularProgressIndicator())
                : !_controller.hasFriends && !_controller.hasSearchResults
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
        if (!_controller.hasSearchResults)
          ..._controller.friends.map((friend) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FriendCard(
              friend: friend,
              showMap: _controller.showMap(friend.uid),
              onToggleMap: () => _controller.toggleShowMap(friend.uid),
              onDelete: () => _handleRemoveFriend(friend.uid),
              isLargePhone: isLargePhone,
              isTablet: isTablet,
            ),
          )),
      ],
    );
  }
}