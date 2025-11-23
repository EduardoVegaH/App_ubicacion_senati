import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';

/// AppBar con título y botón de retroceso
class AppBarWithTitle extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onBack;

  const AppBarWithTitle({
    super.key,
    required this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor ?? AppStyles.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

