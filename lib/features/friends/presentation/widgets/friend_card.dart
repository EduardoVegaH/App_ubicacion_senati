import 'package:flutter/material.dart';
import '../../../../core/widgets/avatar_with_badge/avatar_with_badge.dart';
import '../../../../core/widgets/primary_button/primary_button.dart';
import '../../../../core/widgets/location_info_card/location_info_card.dart';
import '../../../../core/widgets/delete_button/delete_button.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../data/models/friend_model.dart';

/// Card de amigo con información y acciones
class FriendCard extends StatelessWidget {
  /// Datos del amigo
  final FriendModel friend;
  
  /// Si el mapa está visible
  final bool showMap;
  
  /// Función para alternar visibilidad del mapa
  final VoidCallback onToggleMap;
  
  /// Función para eliminar el amigo
  final VoidCallback onDelete;
  
  /// Si es teléfono grande
  final bool isLargePhone;
  
  /// Si es tablet
  final bool isTablet;

  const FriendCard({
    super.key,
    required this.friend,
    required this.showMap,
    required this.onToggleMap,
    required this.onDelete,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.all(
            isLargePhone ? 16 : (isTablet ? 18 : 14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWithBadge(
                    photoUrl: friend.photoUrl,
                    badgeText: statusText,
                    badgeColor: statusColor,
                    size: isLargePhone ? 56 : (isTablet ? 60 : 52),
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
                        const SizedBox(height: 4),
                        Text(
                          friend.status,
                          style: AppTextStyles.bodyTiny(
                            isLargePhone,
                            isTablet,
                          ).copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (friend.latitude != null && friend.longitude != null) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: showMap ? 'Ocultar Mapa' : 'Ver Ubicación en Mapa',
                  icon: showMap ? Icons.arrow_upward : Icons.send,
                  onPressed: onToggleMap,
                  variant: PrimaryButtonVariant.primary,
                  height: isLargePhone ? 44 : (isTablet ? 48 : 40),
                  fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                  responsive: false,
                ),
                if (showMap) ...[
                  const SizedBox(height: 12),
                  LocationInfoCard(
                    name: friend.name,
                    latitude: friend.latitude!,
                    longitude: friend.longitude!,
                  ),
                ],
              ],
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: DeleteButton(
            onTap: onDelete,
          ),
        ),
      ],
    );
  }
}

