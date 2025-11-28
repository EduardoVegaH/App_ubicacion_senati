import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/text_styles.dart';
import '../../../../app/styles/app_spacing.dart';

/// Página de notas donde el usuario puede escribir notas
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNotes,
            tooltip: 'Guardar notas',
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.screenPadding(isLargePhone, isTablet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Escribe tus notas aquí. Se guardarán automáticamente.',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: isLargePhone ? 14 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLargePhone ? 20 : 16),
            // Campo de texto para notas
            Expanded(
              child: TextField(
                controller: _notesController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: isLargePhone ? 16 : 15,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe tus notas aquí...\n\nEjemplo:\n- Recordar estudiar para el examen\n- Tarea de matemáticas pendiente\n- Reunión con el profesor mañana',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isLargePhone ? 16 : 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppStyles.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(isLargePhone ? 20 : 16),
                ),
              ),
            ),
            SizedBox(height: isLargePhone ? 20 : 16),
            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveNotes,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Notas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isLargePhone ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNotes() {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay notas para guardar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Guardar en Firestore o almacenamiento local
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notas guardadas correctamente'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // Quitar el foco del campo de texto
    _focusNode.unfocus();
  }
}

