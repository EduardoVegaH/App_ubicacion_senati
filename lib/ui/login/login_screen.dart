import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'credentials_login_screen.dart';
import 'qr_scan_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C), // Fondo gris oscuro
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo hexagonal azul con "S"
                  _HexagonLogo(),
                  
                  const SizedBox(height: 24),
                  
                  // Título "Sistema de Consulta Estudiantil"
                  const Text(
                    'Sistema de Consulta\nEstudiantil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Texto "Bienvenido"
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón "Escanear QR"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QRScanScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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
                            builder: (context) => const CredentialsLoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  
                  // Texto informativo con icono
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1976D2),
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2C2C2C),
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para el logo hexagonal con "S"
class _HexagonLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            CustomPaint(
              size: const Size(80, 80),
              painter: _HexagonPainter(),
            ),
            CustomPaint(
              size: const Size(80, 80),
              painter: _StyledSPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Clipping para evitar artefactos fuera del área
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dibujar hexágono
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Painter para la "S" estilizada con líneas curvas entrelazadas
class _StyledSPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Clipping para evitar artefactos fuera del área
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    // Curva superior de la S (entrelazada)
    final path1 = Path();
    path1.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.6);
    path1.cubicTo(
      center.dx - radius * 0.4,
      center.dy - radius * 0.9,
      center.dx + radius * 0.1,
      center.dy - radius * 0.9,
      center.dx + radius * 0.4,
      center.dy - radius * 0.6,
    );
    path1.cubicTo(
      center.dx + radius * 0.65,
      center.dy - radius * 0.3,
      center.dx + radius * 0.65,
      center.dy,
      center.dx + radius * 0.4,
      center.dy + radius * 0.2,
    );

    // Curva inferior de la S (entrelazada)
    final path2 = Path();
    path2.moveTo(center.dx + radius * 0.7, center.dy + radius * 0.6);
    path2.cubicTo(
      center.dx + radius * 0.4,
      center.dy + radius * 0.9,
      center.dx - radius * 0.1,
      center.dy + radius * 0.9,
      center.dx - radius * 0.4,
      center.dy + radius * 0.6,
    );
    path2.cubicTo(
      center.dx - radius * 0.65,
      center.dy + radius * 0.3,
      center.dx - radius * 0.65,
      center.dy,
      center.dx - radius * 0.4,
      center.dy - radius * 0.2,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

