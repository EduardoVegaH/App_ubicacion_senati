import 'package:flutter/material.dart';

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
                color: Color(0xFF1B38E3),
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
                  // Logo SENATI
                  Image.asset(
                    'assets/senatilogo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo SENATI
                        Center(
                          child: Image.asset(
                            'assets/senatilogo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        
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
                                color: Color(0xFF1B38E3),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Estudiantil SENATI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B38E3),
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
                              backgroundColor: const Color(0xFF1B38E3),
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
          ],
        ),
      ),
    );
  }
}

