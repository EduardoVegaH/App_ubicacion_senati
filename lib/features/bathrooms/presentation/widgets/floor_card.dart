import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/status_badge/status_badge.dart';
import '../../data/models/bathroom_model.dart';
import '../../domain/entities/bathroom_entity.dart';
import 'bathroom_tile.dart';

/// Card expandible para mostrar un piso con sus baños
class FloorCard extends StatelessWidget {
  final int piso;
  final List<BathroomModel> bathrooms;
  final Function(BathroomModel)? onBathroomTap;
  final bool showEditIcon;
  final bool showBathroomCount;

  const FloorCard({
    super.key,
    required this.piso,
    required this.bathrooms,
    this.onBathroomTap,
    this.showEditIcon = false,
    this.showBathroomCount = false,
  });

  /// Determinar el estado general del piso
  BathroomStatus _getFloorStatus() {
    // Si todos están operativos, el piso está operativo
    if (bathrooms.every((b) => b.estado == BathroomStatus.operativo)) {
      return BathroomStatus.operativo;
    }
    // Si alguno está en limpieza, el piso está en limpieza
    if (bathrooms.any((b) => b.estado == BathroomStatus.en_limpieza)) {
      return BathroomStatus.en_limpieza;
    }
    // Si alguno está inoperativo, el piso está inoperativo
    return BathroomStatus.inoperativo;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
    final floorStatus = _getFloorStatus();

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        border: Border.all(color: AppStyles.greyLight, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isLargePhone ? 18 : (isTablet ? 20 : 16),
            vertical: isLargePhone ? 8 : (isTablet ? 10 : 6),
          ),
          childrenPadding: EdgeInsets.only(
            bottom: isLargePhone ? 8 : (isTablet ? 10 : 6),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: isLargePhone ? 48 : (isTablet ? 52 : 44),
            height: isLargePhone ? 48 : (isTablet ? 52 : 44),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.wc,
                size: isLargePhone ? 24 : (isTablet ? 26 : 22),
                color: AppStyles.primaryColor,
              ),
            ),
          ),
          title: Text(
            'Piso $piso',
            style: AppTextStyles.titleMedium(isLargePhone, isTablet),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: showBathroomCount
                ? Text(
                    '${bathrooms.length} baño${bathrooms.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall(isLargePhone, isTablet, AppStyles.textSecondary),
                  )
                : Row(
                    children: [
                      StatusBadge(
                        label: floorStatus.label,
                        color: floorStatus.color,
                        icon: floorStatus.icon,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargePhone ? 8 : (isTablet ? 10 : 6),
                          vertical: isLargePhone ? 4 : (isTablet ? 5 : 3),
                        ),
                        borderRadius: 6,
                      ),
                    ],
                  ),
          ),
          children: bathrooms.map((bathroom) => BathroomTile(
            bathroom: bathroom,
            onTap: onBathroomTap != null ? () => onBathroomTap!(bathroom) : null,
            showEditIcon: showEditIcon,
          )).toList(),
        ),
      ),
    );
  }
}

