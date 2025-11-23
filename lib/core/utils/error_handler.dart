import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/styles/app_styles.dart';

/// Utilidad para manejar y mostrar errores de forma consistente
class ErrorHandler {
  ErrorHandler._();

  /// Muestra un error de Firebase Auth de forma consistente
  static void showFirebaseError(BuildContext context, FirebaseAuthException e) {
    String errorMessage = 'Error al iniciar sesión';
    
    switch (e.code) {
      case 'invalid-email':
        errorMessage = 'El formato del ID de Estudiante no es válido';
        break;
      case 'user-not-found':
        errorMessage = 'No se encontró una cuenta con este ID de Estudiante';
        break;
      case 'wrong-password':
        errorMessage = 'La contraseña es incorrecta';
        break;
      case 'invalid-credential':
        errorMessage = 'Credenciales inválidas. Verifica tu ID y contraseña';
        break;
      default:
        errorMessage = e.message ?? errorMessage;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppStyles.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Muestra un error genérico
  static void showGenericError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppStyles.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Muestra un error inesperado
  static void showUnexpectedError(BuildContext context, Object error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $error'),
          backgroundColor: AppStyles.errorColor,
        ),
      );
    }
  }
}

