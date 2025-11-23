import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../widgets/index.dart';

/// Página de login principal
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppStyles.paddingHorizontal,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppStyles.surfaceColor,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusL),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo SENATI
                  Image.asset(
                    'assets/senatilogo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Título "Sistema de Consulta Estudiantil"
                  Text(
                    'Sistema de Consulta\nEstudiantil',
                    textAlign: TextAlign.center,
                    style: AppStyles.textH2,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Texto "Bienvenido"
                  Text(
                    'Bienvenido',
                    style: AppStyles.textBody.copyWith(
                      color: AppStyles.textSecondary,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Formulario de login
                  const LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



