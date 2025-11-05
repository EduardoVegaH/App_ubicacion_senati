import 'package:flutter/material.dart';
import 'dart:math' as math;

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C), // Fondo gris oscuro
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior azul con botón Volver
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Volver
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Volver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logo "S" estilizado
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CustomPaint(
                      painter: _SmallStyledSPainter(),
                      size: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo hexagonal azul con "S"
                        const Center(child: _HexagonLogo()),
                        
                        const SizedBox(height: 24),
                        
                        // Título "Sistema de Consulta Estudiantil SENATI"
                        const Column(
                          children: [
                            Text(
                              'Sistema de Consulta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Estudiantil SENATI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Texto descriptivo
                        const Text(
                          'Escanea tu código QR para ver tu\ninformación y horario del día',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF757575),
                            height: 1.4,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Área de escaneo QR (placeholder)
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFFAFAFA),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_scanner,
                              size: 120,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botón "Simular Escaneo QR"
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implementar lógica de escaneo QR
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Simular Escaneo QR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Texto de instrucción
                        const Text(
                          'Coloca el código QR dentro del marco para escanearlo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
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

// Widget para el logo hexagonal con "S" (reutilizado)
class _HexagonLogo extends StatelessWidget {
  const _HexagonLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
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
    );
  }
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;

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
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

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

// Painter para el logo "S" pequeño en la barra superior
class _SmallStyledSPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

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

