import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';

/// Avatar circular con badge de estado
class AvatarWithBadge extends StatelessWidget {
  /// URL de la foto de perfil
  final String? photoUrl;
  
  /// Texto del badge
  final String badgeText;
  
  /// Color del badge
  final Color badgeColor;
  
  /// Tamaño del avatar
  final double? size;
  
  /// Tamaño del icono de placeholder
  final double? placeholderIconSize;
  
  /// Color del borde del avatar
  final Color? borderColor;
  
  /// Ancho del borde del avatar
  final double borderWidth;

  const AvatarWithBadge({
    super.key,
    this.photoUrl,
    required this.badgeText,
    required this.badgeColor,
    this.size,
    this.placeholderIconSize,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    final avatarSize = size ?? (isLargePhone ? 64 : (isTablet ? 70 : 60));
    final hasValidPhotoUrl = photoUrl != null && photoUrl!.isNotEmpty && photoUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: borderColor ?? Colors.white,
              width: borderWidth,
            ),
          ),
          child: hasValidPhotoUrl
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Si hay error cargando la imagen, mostrar el placeholder
                      return Icon(
                        Icons.person,
                        size: placeholderIconSize ??
                            (isLargePhone ? 42 : (isTablet ? 45 : 40)),
                        color: const Color(0xFF757575),
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  size: placeholderIconSize ??
                      (isLargePhone ? 42 : (isTablet ? 45 : 40)),
                  color: const Color(0xFF757575),
                ),
        ),
        // Badge de estado
        Positioned(
          bottom: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.badgeSmall,
            ),
          ),
        ),
      ],
    );
  }
}

