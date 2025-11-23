import 'package:flutter/material.dart';
import '../../../app/styles/app_styles.dart';
import '../../../app/styles/app_shadows.dart';
import '../../../app/styles/text_styles.dart';

/// Barra de búsqueda reutilizable
class CustomSearchBar extends StatefulWidget {
  /// Controlador del campo de texto
  final TextEditingController controller;
  
  /// Placeholder del campo
  final String hintText;
  
  /// Función que se ejecuta cuando cambia el texto
  final ValueChanged<String>? onChanged;
  
  /// Función que se ejecuta al presionar enter
  final VoidCallback? onSubmitted;
  
  /// Función que se ejecuta al limpiar el campo
  final VoidCallback? onClear;
  
  /// Si muestra el botón de limpiar
  final bool showClearButton;
  
  /// Color del icono de búsqueda
  final Color? iconColor;
  
  /// Padding del contenedor
  final EdgeInsets? padding;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Buscar por ID o nombre',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = true,
    this.iconColor,
    this.padding,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        style: AppTextStyles.bodyMedium(isLargePhone, isTablet),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodyMedium(isLargePhone, isTablet)
              .copyWith(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            Icons.search,
            color: widget.iconColor ?? AppStyles.primaryColor,
            size: isLargePhone ? 24 : (isTablet ? 26 : 22),
          ),
          suffixIcon: widget.showClearButton && hasText
              ? IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
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
              color: widget.iconColor ?? AppStyles.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLargePhone ? 20 : (isTablet ? 22 : 16),
            vertical: isLargePhone ? 16 : (isTablet ? 18 : 14),
          ),
        ),
      ),
    );
  }
}
