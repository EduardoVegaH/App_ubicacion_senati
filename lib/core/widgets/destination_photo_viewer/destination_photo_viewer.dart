import 'package:flutter/material.dart';
import '../../../app/styles/app_styles.dart';
import '../../../app/styles/text_styles.dart';

/// Widget que muestra la foto del salón de destino
/// 
/// Muestra una imagen del salón con controles de zoom y información del destino
class DestinationPhotoViewer extends StatefulWidget {
  /// Ruta de la imagen a mostrar
  final String imagePath;
  
  /// Nombre del destino (ej: "Torre B, Piso 2, Salón 200")
  final String destinationName;
  
  /// Número de segmentos de la ruta
  final int routeSegments;
  
  /// Nombre del salón (ej: "Salón 200")
  final String? salonName;
  
  /// Callback cuando se cierra el visor
  final VoidCallback onClose;

  const DestinationPhotoViewer({
    super.key,
    required this.imagePath,
    required this.destinationName,
    required this.routeSegments,
    this.salonName,
    required this.onClose,
  });

  @override
  State<DestinationPhotoViewer> createState() => _DestinationPhotoViewerState();
}

class _DestinationPhotoViewerState extends State<DestinationPhotoViewer> {
  final TransformationController _transformationController = TransformationController();
  bool _imageError = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _transformationController.value = Matrix4.identity()
      ..scale(currentScale * 1.2);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _transformationController.value = Matrix4.identity()
        ..scale((currentScale / 1.2).clamp(1.0, double.infinity));
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Container(
      height: screenSize.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Barra de arrastre
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Contenedor de imagen con controles (cuadrado)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Hacer el contenedor cuadrado (usar el ancho disponible)
                final squareSize = constraints.maxWidth;
                return Center(
                  child: Container(
                    width: squareSize,
                    height: squareSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // Imagen con zoom
                          InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            panEnabled: true,
                            scaleEnabled: true,
                            child: _imageError
                                ? _buildErrorPlaceholder()
                                : Image.asset(
                                    widget.imagePath,
                                    fit: BoxFit.cover,
                                    width: squareSize,
                                    height: squareSize,
                                    errorBuilder: (context, error, stackTrace) {
                                      if (mounted) {
                                        setState(() {
                                          _imageError = true;
                                        });
                                      }
                                      return _buildErrorPlaceholder();
                                    },
                                  ),
                          ),
                        
                        // Botones de control flotantes (esquina superior derecha)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón cerrar
                              _buildControlButton(
                                icon: Icons.close,
                                onPressed: widget.onClose,
                                tooltip: 'Cerrar',
                              ),
                              const SizedBox(height: 8),
                              // Botón zoom in
                              _buildControlButton(
                                icon: Icons.add,
                                onPressed: _zoomIn,
                                tooltip: 'Acercar',
                              ),
                              const SizedBox(height: 8),
                              // Botón zoom out
                              _buildControlButton(
                                icon: Icons.remove,
                                onPressed: _zoomOut,
                                tooltip: 'Alejar',
                              ),
                              const SizedBox(height: 8),
                              // Botón reset zoom
                              _buildControlButton(
                                icon: Icons.center_focus_strong,
                                onPressed: _resetZoom,
                                tooltip: 'Reiniciar zoom',
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Información del destino
          Container(
            padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 20 : 12)),
            decoration: BoxDecoration(
              color: AppStyles.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del destino con icono
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppStyles.primaryColor,
                      size: isLargePhone ? 20 : (isTablet ? 22 : 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destinationName,
                        style: AppTextStyles.bodyBoldMedium(isLargePhone, isTablet),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Información de ruta
                Text(
                  'Ruta: ${widget.routeSegments} segmentos',
                  style: AppTextStyles.bodySmall(isLargePhone, isTablet),
                ),
                // Nombre del salón (si está disponible)
                if (widget.salonName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.salonName!,
                    style: AppTextStyles.bodyTiny(isLargePhone, isTablet).copyWith(
                      color: AppStyles.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

