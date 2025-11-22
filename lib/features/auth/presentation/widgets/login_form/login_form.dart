import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/app/styles/app_styles.dart';
import 'package:flutter_application_1/features/auth/data/index.dart';
import 'package:flutter_application_1/features/auth/domain/index.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import '../index.dart';

/// Widget del formulario de login
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  
  // Inicializar casos de uso
  late final LoginUseCase _loginUseCase;
  
  @override
  void initState() {
    super.initState();
    final dataSource = AuthRemoteDataSource();
    final repository = AuthRepositoryImpl(dataSource);
    _loginUseCase = LoginUseCase(repository);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    // Validar formato de email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    // Si no tiene @, agregar @senati.pe
    String finalEmail = email;
    if (!email.contains('@')) {
      finalEmail = '$email@senati.pe';
    } else if (!emailRegex.hasMatch(finalEmail)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El formato del ID de Estudiante no es válido'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _loginUseCase.call(finalEmail, password);

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppStyles.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón "Escanear QR"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QRScanForm(),
                  ),
                );
              },
              style: AppStyles.elevatedButtonStyle,
              icon: const Icon(Icons.qr_code_scanner, size: 24),
              label: const Text(
                'Escanear QR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
      ),
    );
  }
}

