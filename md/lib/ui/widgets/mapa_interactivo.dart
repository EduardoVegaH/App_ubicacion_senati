import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget interactivo que carga un SVG, permite zoom/pan y detecta toques
/// sobre elementos del SVG devolviendo el ID del salón tocado
class MapaInteractivo extends StatefulWidget {
  /// Ruta del archivo SVG en assets
  final String svgAssetPath;
  
  /// Callback que se ejecuta cuando se toca un elemento del SVG
  /// Recibe el ID del elemento tocado (puede ser null si no se encuentra)
  final Function(String?)? onElementTapped;
  
  /// Altura del widget (null para pantalla completa)
  final double? height;
  
  /// Muestra controles de zoom y reset
  final bool showControls;
  
  /// Escala mínima de zoom
  final double minScale;
  
  /// Escala máxima de zoom
  final double maxScale;

  const MapaInteractivo({
    super.key,
    required this.svgAssetPath,
    this.onElementTapped,
    this.height,
    this.showControls = true,
    this.minScale = 0.5,
    this.maxScale = 4.0,
  });

  @override
  State<MapaInteractivo> createState() => _MapaInteractivoState();
}

class _MapaInteractivoState extends State<MapaInteractivo> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _svgKey = GlobalKey();
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Size? _svgSize;
  Size? _widgetSize;

  @override
  void initState() {
    super.initState();
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

  /// Convierte las coordenadas del toque en el widget a coordenadas del SVG
  /// Nota: Esta es una aproximación. Para mayor precisión, necesitarías
  /// parsear el SVG y obtener sus dimensiones exactas.
  Offset _convertToSvgCoordinates(Offset localPosition) {
    if (_widgetSize == null) return Offset.zero;

    // Obtener la transformación actual
    final matrix = _transformationController.value;
    
    // Invertir la transformación para obtener coordenadas originales
    final invertedMatrix = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(invertedMatrix, localPosition);
    
    // Si no tenemos el tamaño del SVG, usar el tamaño del widget como aproximación
    // En una implementación completa, deberías parsear el SVG para obtener sus dimensiones reales
    final estimatedSvgSize = _svgSize ?? _widgetSize!;
    
    // Calcular el tamaño del SVG renderizado
    final svgAspectRatio = estimatedSvgSize.width / estimatedSvgSize.height;
    final widgetAspectRatio = _widgetSize!.width / _widgetSize!.height;
    
    double svgDisplayWidth;
    double svgDisplayHeight;
    double svgOffsetX = 0;
    double svgOffsetY = 0;
    
    if (svgAspectRatio > widgetAspectRatio) {
      // SVG es más ancho, se ajusta al ancho del widget
      svgDisplayWidth = _widgetSize!.width;
      svgDisplayHeight = _widgetSize!.width / svgAspectRatio;
      svgOffsetY = (_widgetSize!.height - svgDisplayHeight) / 2;
    } else {
      // SVG es más alto, se ajusta a la altura del widget
      svgDisplayHeight = _widgetSize!.height;
      svgDisplayWidth = _widgetSize!.height * svgAspectRatio;
      svgOffsetX = (_widgetSize!.width - svgDisplayWidth) / 2;
    }
    
    // Convertir coordenadas del widget a coordenadas del SVG
    final svgX = ((transformedPoint.dx - svgOffsetX) / svgDisplayWidth) * estimatedSvgSize.width;
    final svgY = ((transformedPoint.dy - svgOffsetY) / svgDisplayHeight) * estimatedSvgSize.height;
    
    return Offset(svgX, svgY);
  }

  /// Detecta qué elemento del SVG fue tocado basándose en las coordenadas
  /// Nota: Esta es una implementación básica. Para una detección precisa,
  /// necesitarías parsear el SVG y verificar cada elemento.
  Future<String?> _detectTappedElement(Offset svgCoordinates) async {
    // Por ahora, devolvemos las coordenadas como ID
    // En una implementación completa, aquí parsearías el SVG y buscarías
    // qué elemento contiene estas coordenadas
    
    // Ejemplo: Si el SVG tiene elementos con IDs como "salon-201", "salon-202", etc.
    // Podrías tener un mapa de áreas y verificar si las coordenadas están dentro
    
    // Por ahora, retornamos un ID basado en las coordenadas
    // Esto es un placeholder - deberías implementar la lógica real de detección
    final roomId = 'salon-${svgCoordinates.dx.toInt()}-${svgCoordinates.dy.toInt()}';
    
    return roomId;
  }

  void _handleTapDown(TapDownDetails details) async {
    if (widget.onElementTapped == null) return;
    
    // Obtener el RenderBox del widget
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    // Convertir coordenadas globales a locales
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Convertir a coordenadas del SVG
    final svgCoordinates = _convertToSvgCoordinates(localPosition);
    
    // Detectar qué elemento fue tocado
    final elementId = await _detectTappedElement(svgCoordinates);
    
    // Ejecutar callback
    widget.onElementTapped?.call(elementId);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;
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
            child: GestureDetector(
              onTapDown: _handleTapDown,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                panEnabled: true,
                scaleEnabled: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Guardar el tamaño del widget
                    _widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
                    
                    return SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: SvgPicture.asset(
                          widget.svgAssetPath,
                          key: _svgKey,
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  },
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

          // Indicador de zoom
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

          // Instrucciones de uso
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
                        'Toca un salón para ver su información',
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

