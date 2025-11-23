import 'package:flutter/material.dart';
import '../../domain/entities/bathroom_entity.dart';
import '../../data/models/bathroom_model.dart';
import 'status_option.dart';

/// Diálogo para cambiar el estado de un baño
class BathroomStatusDialog extends StatelessWidget {
  final BathroomModel bathroom;
  final Function(BathroomStatus) onStatusSelected;

  const BathroomStatusDialog({
    super.key,
    required this.bathroom,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cambiar estado: ${bathroom.nombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusOption(
            status: BathroomStatus.operativo,
            isSelected: bathroom.estado == BathroomStatus.operativo,
            onTap: () {
              Navigator.pop(context);
              onStatusSelected(BathroomStatus.operativo);
            },
          ),
          const SizedBox(height: 8),
          StatusOption(
            status: BathroomStatus.en_limpieza,
            isSelected: bathroom.estado == BathroomStatus.en_limpieza,
            onTap: () {
              Navigator.pop(context);
              onStatusSelected(BathroomStatus.en_limpieza);
            },
          ),
          const SizedBox(height: 8),
          StatusOption(
            status: BathroomStatus.inoperativo,
            isSelected: bathroom.estado == BathroomStatus.inoperativo,
            onTap: () {
              Navigator.pop(context);
              onStatusSelected(BathroomStatus.inoperativo);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

