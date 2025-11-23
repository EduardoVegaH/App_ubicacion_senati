import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/styles/app_styles.dart';
import 'package:flutter_application_1/app/styles/text_styles.dart';
import '../index.dart';

/// Widget del formulario de login (pantalla inicial)
class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Botón "Iniciar Sesión"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CredentialsLoginForm(),
                  ),
                );
              },
              style: AppStyles.outlinedButtonStyle,
              icon: const Icon(Icons.person, size: 24),
              label: const Text(
                'Iniciar Sesión',
                style: AppTextStyles.buttonText,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Texto informativo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Elige cómo deseas acceder a tu información académica',
                  textAlign: TextAlign.center,
                  style: AppStyles.textSmall.copyWith(
                    color: AppStyles.textPrimary,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

