import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/app_shadows.dart';

/// Widget que muestra un pop-up estilo Google Maps con la foto del salón
/// Aparece desde abajo con animación
class SalonPhotoPopup extends StatefulWidget {
  /// Ruta de la imagen a mostrar
  final String imagePath;
  
  /// Callback cuando se cierra el pop-up
  final VoidCallback onClose;
  
  /// Controlador de animación
  final AnimationController animationController;

  const SalonPhotoPopup({
    super.key,
    required this.imagePath,
    required this.onClose,
    required this.animationController,
  });

  @override
  State<SalonPhotoPopup> createState() => _SalonPhotoPopupState();
}

class _SalonPhotoPopupState extends State<SalonPhotoPopup> {
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Comienza desde abajo
      end: Offset.zero, // Termina en su posición normal
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo semitransparente que cierra al tocar
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: AppStyles.blackOverlayBackdrop,
          ),
        ),
        // Contenedor de imagen con animación desde abajo (estilo Google Maps)
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: AppShadows.popupShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra de arrastre (indicador visual)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Contenedor de la imagen
                  Container(
                    width: double.infinity,
                    height: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        // Imagen en contenedor cuadrado
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 350,
                            child: Image.asset(
                              widget.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('❌ Error al cargar imagen: $error');
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Imagen no encontrada',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Botón para cerrar (estilo Google Maps)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              onTap: widget.onClose,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Espacio inferior
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

