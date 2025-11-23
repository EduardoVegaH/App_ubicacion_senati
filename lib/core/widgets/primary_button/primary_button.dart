import 'package:flutter/material.dart';
import '../../../app/styles/app_styles.dart';
import '../../../app/styles/text_styles.dart';

/// Variante del botón primario
enum PrimaryButtonVariant {
  /// Botón primario azul (Color(0xFF1B38E3))
  primary,
  
  /// Botón secundario azul celeste (Color(0xFF3D79FF))
  secondary,
}

/// Botón primario reutilizable con estilo consistente
/// 
/// Usado para acciones principales como:
/// - "Iniciar Sesión"
/// - "Ver Ubicación en Mapa"
/// - "Navegar Ahora (Tiempo Real)"
class PrimaryButton extends StatelessWidget {
  /// Texto del botón
  final String label;
  
  /// Función a ejecutar al presionar
  final VoidCallback? onPressed;
  
  /// Icono del botón (opcional)
  final IconData? icon;
  
  /// Si está en estado de carga
  final bool isLoading;
  
  /// Variante del botón (primary o secondary)
  final PrimaryButtonVariant variant;
  
  /// Si el botón debe ocupar todo el ancho disponible
  final bool fullWidth;
  
  /// Altura del botón (opcional, se calcula automáticamente si no se proporciona)
  final double? height;
  
  /// Tamaño de fuente (opcional, se calcula automáticamente si no se proporciona)
  final double? fontSize;
  
  /// Si es responsive (ajusta tamaño según pantalla)
  final bool responsive;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = PrimaryButtonVariant.primary,
    this.fullWidth = true,
    this.height,
    this.fontSize,
    this.responsive = true,
  });

  @override
  Widget build(BuildContext context) {
    // Solo calcular tamaños responsive si es necesario
    double buttonHeight;
    double buttonFontSize;
    double iconSize;
    EdgeInsets buttonPadding;
    
    if (responsive) {
      final screenSize = MediaQuery.of(context).size;
      final isTablet = screenSize.width > 600;
      final isLargePhone = screenSize.width >= 400 && !isTablet;
      
      buttonHeight = height ?? _size(44, 48, 50, isLargePhone, isTablet);
      buttonFontSize = fontSize ?? _size(14, 15, 16, isLargePhone, isTablet);
      iconSize = _size(18, 20, 22, isLargePhone, isTablet);
      buttonPadding = EdgeInsets.symmetric(
        horizontal: _size(20, 24, 28, isLargePhone, isTablet),
        vertical: _size(12, 14, 16, isLargePhone, isTablet),
      );
    } else {
      // Valores fijos cuando no es responsive
      buttonHeight = height ?? 50;
      buttonFontSize = fontSize ?? 16;
      iconSize = 20;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
    
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _buildStyle(buttonPadding),
      child: _buildContent(buttonFontSize, iconSize),
    );
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: buttonHeight,
      child: button,
    );
  }

  /// Calcula tamaño responsive de forma simplificada
  double _size(double small, double large, double tablet, bool isLargePhone, bool isTablet) {
    if (isTablet) return tablet;
    if (isLargePhone) return large;
    return small;
  }

  /// Construye el contenido del botón (loading, icon+texto, o solo texto)
  Widget _buildContent(double fontSize, double iconSize) {
    if (isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    
    if (icon != null) {
      return _buildIconWithText(fontSize, iconSize);
    }
    
    return _buildTextOnly(fontSize);
  }

  /// Construye botón con icono y texto
  Widget _buildIconWithText(double fontSize, double iconSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.buttonTextDynamic(fontSize),
        ),
      ],
    );
  }

  /// Construye botón solo con texto
  Widget _buildTextOnly(double fontSize) {
    return Text(
      label,
      style: AppTextStyles.buttonTextDynamic(fontSize),
    );
  }

  /// Construye el estilo del botón
  ButtonStyle _buildStyle(EdgeInsets padding) {
    final backgroundColor = variant == PrimaryButtonVariant.primary
        ? AppStyles.primaryColor
        : const Color(0xFF3D79FF);
    
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusM),
      ),
      elevation: 0,
      padding: padding,
    );
  }
}

