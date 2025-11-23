import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_shadows.dart';

/// Avatar circular para mensajes de chat
class ChatAvatar extends StatelessWidget {
  /// Si es true, muestra avatar de usuario, si es false, muestra avatar de asistente
  final bool isUser;
  
  /// Tamaño del avatar
  final double size;
  
  /// Tamaño del icono interno
  final double? iconSize;

  const ChatAvatar({
    super.key,
    required this.isUser,
    this.size = 32.0,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final finalIconSize = iconSize ?? (size * 0.56); // ~18px para 32px, proporcional
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isUser ? Colors.white : AppStyles.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser ? AppStyles.primaryColor : Colors.white,
          width: 2,
        ),
        boxShadow: AppShadows.messageShadow,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: finalIconSize,
        color: isUser ? AppStyles.primaryColor : Colors.white,
      ),
    );
  }
}

