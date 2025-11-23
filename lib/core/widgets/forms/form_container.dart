import 'package:flutter/material.dart';

/// Contenedor de formulario con estilo consistente
class FormContainer extends StatelessWidget {
  /// Contenido del formulario
  final Widget child;
  
  /// Padding interno del contenedor
  final EdgeInsets? padding;
  
  /// Ancho máximo del contenedor
  final double? maxWidth;
  
  /// Widget de encabezado (logo, título, etc.)
  final Widget? header;
  
  /// Espaciado entre el header y el contenido
  final double headerSpacing;

  const FormContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 400,
    this.header,
    this.headerSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 32,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            SizedBox(height: headerSpacing),
          ],
          child,
        ],
      ),
    );
  }
}

