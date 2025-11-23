import 'package:flutter/material.dart';
import '../../../../core/widgets/avatar_with_badge/avatar_with_badge.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../data/models/friend_model.dart';

/// Card de resultado de búsqueda
class SearchResultCard extends StatelessWidget {
  /// Datos del amigo encontrado
  final FriendModel friend;
  
  /// Si ya es amigo
  final bool isFriend;
  
  /// Función para agregar el amigo
  final VoidCallback onAdd;
  
  /// Función para eliminar el amigo
  final VoidCallback onRemove;
  
  /// Si es teléfono grande
  final bool isLargePhone;
  
  /// Si es tablet
  final bool isTablet;

  const SearchResultCard({
    super.key,
    required this.friend,
    required this.isFriend,
    required this.onAdd,
    required this.onRemove,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        isLargePhone ? 16 : (isTablet ? 18 : 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvatarWithBadge(
            photoUrl: friend.photoUrl,
            badgeText: friend.isPresent ? 'Presente' : 'Ausente',
            badgeColor: friend.isPresent ? Colors.green : Colors.red,
            size: isLargePhone ? 60 : (isTablet ? 64 : 56),
            borderColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: AppTextStyles.titleSmall(
                    isLargePhone,
                    isTablet,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${friend.id}',
                  style: AppTextStyles.bodySmall(
                    isLargePhone,
                    isTablet,
                  ).copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isFriend ? onRemove : onAdd,
            icon: Icon(
              isFriend ? Icons.remove_circle : Icons.add_circle,
              color: isFriend ? Colors.red : const Color(0xFF1B38E3),
              size: 32,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isFriend ? 'Eliminar amigo' : 'Agregar amigo',
          ),
        ],
      ),
    );
  }
}

