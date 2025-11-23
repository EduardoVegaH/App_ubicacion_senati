import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/auth/data/index.dart';
import 'package:flutter_application_1/features/auth/domain/index.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import '../../../../../core/widgets/index.dart';
import '../../../../../core/utils/error_handler.dart';

/// Widget del formulario de login con credenciales
class CredentialsLoginForm extends StatefulWidget {
  const CredentialsLoginForm({super.key});

  @override
  State<CredentialsLoginForm> createState() => _CredentialsLoginFormState();
}

class _CredentialsLoginFormState extends State<CredentialsLoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  
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

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    String finalEmail = email;
    if (!email.contains('@')) {
      finalEmail = '$email@senati.pe';
    } else if (!emailRegex.hasMatch(finalEmail)) {
      if (mounted) {
        ErrorHandler.showGenericError(
          context,
          'El formato del ID de Estudiante no es válido',
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
      if (mounted) {
        ErrorHandler.showFirebaseError(context, e);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showUnexpectedError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            const AppBarWithBack(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FormContainer(
                    header: Column(
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/senatilogo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ingresa tus credenciales',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.formTitle,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          FormFieldWithLabel(
                            label: 'ID de Estudiante',
                            controller: _emailCtrl,
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu ID de Estudiante';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          PasswordField(
                            controller: _passCtrl,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Iniciar Sesión',
                            onPressed: _handleLogin,
                            isLoading: _loading,
                            height: 50,
                            fontSize: 16,
                            responsive: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
