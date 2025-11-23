import 'package:flutter/material.dart';
import 'form_field_with_label.dart';

/// Campo de contraseña con toggle de visibilidad
class PasswordField extends StatefulWidget {
  /// Controlador del campo
  final TextEditingController controller;
  
  /// Validador del campo
  final String? Function(String?)? validator;
  
  /// Label del campo
  final String label;
  
  /// Texto de ayuda
  final String? hintText;
  
  /// Si el campo está habilitado
  final bool enabled;

  const PasswordField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Contraseña',
    this.hintText,
    this.enabled = true,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormFieldWithLabel(
      label: widget.label,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      prefixIcon: Icons.lock,
      suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
      onSuffixIconTap: _toggleVisibility,
      hintText: widget.hintText,
      enabled: widget.enabled,
    );
  }
}

