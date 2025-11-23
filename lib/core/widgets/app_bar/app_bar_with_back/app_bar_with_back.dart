import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/text_styles.dart';

/// AppBar con botón "Volver" y logo
class AppBarWithBack extends StatelessWidget {
  /// Callback cuando se presiona el botón "Volver"
  final VoidCallback? onBack;
  
  /// Ruta del logo
  final String? logoPath;
  
  /// Tamaño del logo
  final double? logoSize;
  
  /// Texto del botón "Volver"
  final String backText;
  
  /// Color de fondo del AppBar
  final Color? backgroundColor;

  const AppBarWithBack({
    super.key,
    this.onBack,
    this.logoPath = 'assets/senatilogo.png',
    this.logoSize = 40,
    this.backText = 'Volver',
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyles.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  backText,
                  style: AppTextStyles.formBack,
                ),
              ],
            ),
          ),
          if (logoPath != null)
            Image.asset(
              logoPath!,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}

