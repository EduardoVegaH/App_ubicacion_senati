import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';

/// Campo de formulario con label y estilo consistente
class FormFieldWithLabel extends StatelessWidget {
  /// Label del campo
  final String label;
  
  /// Controlador del campo
  final TextEditingController controller;
  
  /// Validador del campo
  final String? Function(String?)? validator;
  
  /// Icono del prefijo
  final IconData? prefixIcon;
  
  /// Icono del sufijo
  final IconData? suffixIcon;
  
  /// Callback cuando se presiona el icono del sufijo
  final VoidCallback? onSuffixIconTap;
  
  /// Si el texto debe estar oculto (para contraseñas)
  final bool obscureText;
  
  /// Texto de ayuda
  final String? hintText;
  
  /// Tipo de teclado
  final TextInputType? keyboardType;
  
  /// Si el campo está habilitado
  final bool enabled;
  
  /// Espaciado entre el label y el campo
  final double labelSpacing;

  const FormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.hintText,
    this.keyboardType,
    this.enabled = true,
    this.labelSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.formLabel,
        ),
        SizedBox(height: labelSpacing),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: const Color(0xFF757575),
                  )
                : null,
            suffixIcon: suffixIcon != null && onSuffixIconTap != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: const Color(0xFF757575),
                    ),
                    onPressed: onSuffixIconTap,
                  )
                : null,
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}

