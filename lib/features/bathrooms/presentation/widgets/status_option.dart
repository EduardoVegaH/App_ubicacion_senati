import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../domain/entities/bathroom_entity.dart';
import '../../data/models/bathroom_model.dart';

/// Opción de estado seleccionable para baños
class StatusOption extends StatelessWidget {
  final BathroomStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusOption({
    super.key,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? status.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? status.color : AppStyles.greyLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(status.icon, size: 24, color: status.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: status.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: status.color),
          ],
        ),
      ),
    );
  }
}

