import 'package:flutter/material.dart';
import '../../utils/initialize_salones.dart';

/// Pantalla de administración para inicializar salones en Firebase
/// Permite crear y limpiar la colección de salones
class SalonesAdminScreen extends StatefulWidget {
  const SalonesAdminScreen({super.key});

  @override
  State<SalonesAdminScreen> createState() => _SalonesAdminScreenState();
}

class _SalonesAdminScreenState extends State<SalonesAdminScreen> {
  final SalonesInitializer _initializer = SalonesInitializer();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Salones'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inicialización de Salones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta herramienta permite inicializar la base de datos de salones en Firebase Firestore.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_statusMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.error,
                              color: _isSuccess ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _inicializarSalones,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Inicializar Salones en Firebase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _limpiarSalones,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Limpiar Todos los Salones'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.info_outline,
                      'Los salones se crearán con sus coordenadas (x, y) y conexiones.',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.map_outlined,
                      'Incluye salones de las Torres A, B y C en diferentes pisos.',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.link,
                      'Cada salón tiene conexiones con pasillos, escaleras y otros salones.',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.warning_amber,
                      'Limpiar eliminará TODOS los salones. Usa con precaución.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _inicializarSalones() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _initializer.initializeSalones();
      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Salones inicializados correctamente en Firebase.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error al inicializar salones: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _limpiarSalones() async {
    // Confirmar antes de limpiar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text(
          'Esta acción eliminará TODOS los salones de Firebase. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _initializer.clearSalones();
      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Todos los salones han sido eliminados.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error al limpiar salones: $e';
        _isSuccess = false;
      });
    }
  }
}

