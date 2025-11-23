import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/drawer/index.dart' as drawer_widgets;
import '../models/drawer_menu_item.dart';

/// Widget para el drawer lateral (refactorizado)
class HomeDrawer extends StatelessWidget {
  /// Lista de items del menú
  final List<DrawerMenuItem> menuItems;
  
  /// Función a ejecutar al cerrar el drawer
  final VoidCallback? onClose;
  
  /// Si es un teléfono grande
  final bool isLargePhone;
  
  /// Si es una tablet
  final bool isTablet;

  const HomeDrawer({
    super.key,
    required this.menuItems,
    this.onClose,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular indentación para separadores
    final separatorIndent = isLargePhone ? 56.0 : (isTablet ? 60.0 : 52.0);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.primaryColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header del drawer
              drawer_widgets.CustomDrawerHeader(
                title: 'Menú',
                onClose: onClose ?? () => Navigator.of(context).pop(),
                isLargePhone: isLargePhone,
                isTablet: isTablet,
              ),
              // Separador
              drawer_widgets.DrawerSeparator(
                indent: 0,
              ),
              const SizedBox(height: 8),
              // Opciones del menú
              Expanded(
                child: ListView(
                  padding: AppSpacing.screenPadding(isLargePhone, isTablet).copyWith(
                    top: 8,
                    bottom: 8,
                  ),
                  children: [
                    // Construir items del menú con separadores (excluyendo logout)
                    ...menuItems.where((item) => !item.isLogout).expand((item) {
                      final widgets = <Widget>[
                        drawer_widgets.DrawerItem(
                          icon: item.icon,
                          title: item.title,
                          onTap: item.onTap,
                          isLogout: false,
                          isLargePhone: isLargePhone,
                          isTablet: isTablet,
                        ),
                      ];
                      
                      if (item.showSeparator) {
                        widgets.add(
                          drawer_widgets.DrawerSeparator(
                            indent: separatorIndent,
                          ),
                        );
                      }
                      
                      return widgets;
                    }),
                  ],
                ),
              ),
              // Separador antes de cerrar sesión (si hay items de logout)
              if (menuItems.any((item) => item.isLogout)) ...[
                drawer_widgets.DrawerSeparator(
                  indent: 0,
                ),
                const SizedBox(height: 8),
                // Botón Cerrar Sesión (último item si es logout)
                Padding(
                  padding: AppSpacing.screenPadding(isLargePhone, isTablet).copyWith(
                    top: 8,
                    bottom: 8,
                  ),
                  child: Builder(
                    builder: (context) {
                      final logoutItem = menuItems.firstWhere(
                        (item) => item.isLogout,
                        orElse: () => menuItems.last,
                      );
                      
                      return drawer_widgets.DrawerItem(
                        icon: logoutItem.icon,
                        title: logoutItem.title,
                        onTap: logoutItem.onTap,
                        isLogout: logoutItem.isLogout,
                        isLargePhone: isLargePhone,
                        isTablet: isTablet,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
