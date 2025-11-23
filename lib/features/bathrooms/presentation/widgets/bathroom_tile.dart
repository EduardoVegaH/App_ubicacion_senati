import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/status_badge/status_badge.dart';
import '../../data/models/bathroom_model.dart';
import '../../domain/entities/bathroom_entity.dart';

/// Tile individual para mostrar un baño con su estado
class BathroomTile extends StatelessWidget {
  final BathroomModel bathroom;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const BathroomTile({
    super.key,
    required this.bathroom,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
    final dateFormat = DateFormat('HH:mm');

    final tile = Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargePhone ? 18 : (isTablet ? 20 : 16),
        vertical: 4,
      ),
      padding: AppSpacing.cardPaddingSmall(isLargePhone, isTablet),
      decoration: BoxDecoration(
        color: bathroom.estado.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bathroom.estado.color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            bathroom.estado.icon,
            size: isLargePhone ? 20 : (isTablet ? 22 : 18),
            color: bathroom.estado.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bathroom.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  label: bathroom.estado.label,
                  color: bathroom.estado.color,
                  icon: bathroom.estado.icon,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargePhone ? 8 : (isTablet ? 10 : 6),
                    vertical: isLargePhone ? 4 : (isTablet ? 5 : 3),
                  ),
                  borderRadius: 6,
                ),
                if (bathroom.estado == BathroomStatus.en_limpieza &&
                    bathroom.usuarioLimpiezaNombre != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: isLargePhone ? 14 : (isTablet ? 15 : 13),
                        color: AppStyles.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        bathroom.usuarioLimpiezaNombre!,
                        style: TextStyle(
                          color: AppStyles.textSecondary,
                          fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                        ),
                      ),
                      if (bathroom.inicioLimpieza != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: isLargePhone ? 14 : (isTablet ? 15 : 13),
                          color: AppStyles.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(bathroom.inicioLimpieza!),
                          style: TextStyle(
                            color: AppStyles.textSecondary,
                            fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (showEditIcon)
            Icon(
              Icons.edit,
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
              color: bathroom.estado.color,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: tile,
      );
    }

    return tile;
  }
}

