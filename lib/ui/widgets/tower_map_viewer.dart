import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget interactivo para mostrar los mapas de las torres SENATI
/// Con funcionalidad de zoom, pan y cambio entre vista exterior/interior
class TowerMapViewer extends StatefulWidget {
  final double? height;
  final bool showControls;
  final String? initialView; // 'exterior' o 'interior'

  const TowerMapViewer({
    super.key,
    this.height,
    this.showControls = true,
    this.initialView,
  });

  @override
  State<TowerMapViewer> createState() => _TowerMapViewerState();
}

class _TowerMapViewerState extends State<TowerMapViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isExteriorView = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.initialView == 'interior') {
      _isExteriorView = false;
    }
    _transformationController.addListener(() {
      final value = _transformationController.value;
      setState(() {
        _scale = value.getMaxScaleOnAxis();
        _offset = Offset(value.getTranslation().x, value.getTranslation().y);
      });
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _toggleView() {
    setState(() {
      _isExteriorView = !_isExteriorView;
      // Resetear zoom al cambiar de vista
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    // Si height es null (pantalla completa), no mostrar borde ni bordes redondeados
    final bool isFullScreen = widget.height == null;
    
    Widget mapContainer = Container(
      decoration: BoxDecoration(
        border: isFullScreen ? null : Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: isFullScreen ? null : BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Mapa interactivo con zoom y pan
          ClipRRect(
            borderRadius: isFullScreen ? BorderRadius.zero : BorderRadius.circular(12),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: _isExteriorView
                      ? SvgPicture.asset(
                          'assets/Torres_ext.svg',
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/Torres_int.svg',
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Controles superiores
          if (widget.showControls)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  // Botón para cambiar entre vista exterior/interior
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      onTap: _toggleView,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExteriorView
                                  ? Icons.business
                                  : Icons.home,
                              size: 18,
                              color: const Color(0xFF1B38E3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isExteriorView ? 'Exterior' : 'Interior',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B38E3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botón para resetear zoom
                  if (_scale > 1.1 || _offset.distance > 10)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      elevation: 2,
                      child: InkWell(
                        onTap: _resetZoom,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.center_focus_strong,
                            size: 18,
                            color: Color(0xFF1B38E3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Indicador de zoom en la esquina inferior izquierda
          if (widget.showControls && _scale > 1.1)
            Positioned(
              bottom: 8,
              left: 8,
              child: Material(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    '${(_scale * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Instrucciones de uso (solo cuando no hay zoom)
          if (widget.showControls && _scale <= 1.1 && _offset.distance < 10)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pellizca para hacer zoom • Arrastra para mover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargePhone ? 10 : 9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Si height es null, retornar el container sin SizedBox (para pantalla completa)
    if (widget.height == null) {
      return mapContainer;
    }

    // Si height está definido, envolver en SizedBox
    final mapHeight = widget.height ??
        (isLargePhone ? 220 : (isTablet ? 250 : 200));
    return SizedBox(
      height: mapHeight,
      child: mapContainer,
    );
  }
}

