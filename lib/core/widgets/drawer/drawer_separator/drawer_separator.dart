import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';

/// Separador reutilizable para drawer/menú lateral
class DrawerSeparator extends StatelessWidget {
  /// Indentación del separador (desde el borde izquierdo)
  final double indent;
  
  /// Color del separador (opcional)
  final Color? color;
  
  /// Grosor del separador
  final double thickness;
  
  /// Altura del separador
  final double height;

  const DrawerSeparator({
    super.key,
    required this.indent,
    this.color,
    this.thickness = 1.0,
    this.height = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: color ?? AppStyles.textOnDark.withOpacity(0.2),
      thickness: thickness,
      height: height,
      indent: indent,
    );
  }
}

