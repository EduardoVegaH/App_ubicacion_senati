import 'package:flutter/material.dart';
import '../../domain/entities/map_node.dart';

/// CustomPainter que dibuja la ruta sobre el mapa
/// 
/// Dibuja líneas conectando los nodos en orden y marca el destino
/// Transforma coordenadas del SVG al canvas considerando el aspect ratio
class MapRoutePainter extends CustomPainter {
  final List<MapNode> pathNodes;
  final Color routeColor;
  final Color destinationColor;
  final double routeWidth;
  
  /// Dimensiones del SVG (viewBox)
  final double svgWidth;
  final double svgHeight;
  
  /// Nodo de inicio (entrada) para resaltar
  final MapNode? entranceNode;
  
  /// Coordenadas del marcador del usuario (en coordenadas SVG)
  final double? markerX;
  final double? markerY;
  
  /// Índice del nodo más cercano (si el marcador está "atrapado" en un nodo)
  final int? nearestNodeIndex;
  
  /// Heading (orientación) del marcador en radianes
  final double? markerHeading;
  
  /// Índice del último segmento completado (para "comerse" la ruta ya recorrida)
  final int completedSegmentsIndex;
  
  /// Tamaño del punto de inicio (radio del círculo)
  final double? startNodeRadius;
  
  /// Tamaño del punto de destino (radio del círculo)
  final double? destinationNodeRadius;
  
  /// Nombre del salón destino (para mostrar en la etiqueta)
  final String? destinationSalonName;

  MapRoutePainter({
    required this.pathNodes,
    this.entranceNode,
    this.markerX,
    this.markerY,
    this.nearestNodeIndex,
    this.markerHeading,
    this.completedSegmentsIndex = -1, // -1 significa que no se ha completado ningún segmento
    this.routeColor = const Color(0xFF1B38E3),
    this.destinationColor = const Color(0xFF87CEEB), // Celeste claro
    this.routeWidth = 2.5,
    this.svgWidth = 2117.0, // viewBox width del SVG piso 2 (por defecto)
    this.svgHeight = 1729.0, // viewBox height del SVG piso 2 (por defecto)
    this.startNodeRadius,
    this.destinationNodeRadius,
    this.destinationSalonName,
  });

  /// Transforma coordenadas del SVG a coordenadas del canvas
  /// Considera el aspect ratio y el centrado (BoxFit.contain)
  Offset _transformPoint(double x, double y, Size canvasSize) {
    // Calcular escala para mantener aspect ratio (BoxFit.contain)
    final scaleX = canvasSize.width / svgWidth;
    final scaleY = canvasSize.height / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calcular offset para centrar
    final scaledWidth = svgWidth * scale;
    final scaledHeight = svgHeight * scale;
    final offsetX = (canvasSize.width - scaledWidth) / 2;
    final offsetY = (canvasSize.height - scaledHeight) / 2;
    
    // Transformar coordenadas
    return Offset(
      offsetX + x * scale,
      offsetY + y * scale,
    );
  }
  
  /// Extrae el nombre del salón o área desde el nodo destino
  String? _extractSalonName(MapNode? node) {
    if (node == null) return null;
    
    // Si ya tenemos el nombre proporcionado, usarlo
    if (destinationSalonName != null && destinationSalonName!.isNotEmpty) {
      return destinationSalonName;
    }
    
    // Intentar extraer del ID del nodo
    final nodeId = node.id.toLowerCase();
    
    // Mapear áreas comunes del piso 1
    final areaMapping = {
      'comedor': 'Comedor',
      'biblio': 'Biblioteca',
      'biblioteca': 'Biblioteca',
      'oficina': 'Oficina',
      'escaleras': 'Escaleras',
      'main01': 'Entrada Principal',
      'main02': 'Entrada Principal',
    };
    
    // Verificar si es un área común del piso 1
    for (final entry in areaMapping.entries) {
      if (nodeId.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Patrón: node-salon-A-200 o node-salon-B-200
    final salonMatch = RegExp(r'salon-([a-c])-(\d+)', caseSensitive: false).firstMatch(nodeId);
    if (salonMatch != null) {
      final torre = salonMatch.group(1)!.toUpperCase();
      final numero = salonMatch.group(2)!;
      return 'Salón $torre-$numero';
    }
    
    // Patrón: node#XX_sal#A200
    final salMatch = RegExp(r'sal#([a-c])(\d+)', caseSensitive: false).firstMatch(nodeId);
    if (salMatch != null) {
      final torre = salMatch.group(1)!.toUpperCase();
      final numero = salMatch.group(2)!;
      return 'Salón $torre-$numero';
    }
    
    return null;
  }
  
  /// Dibuja una etiqueta de texto con fondo
  void _drawLabel(Canvas canvas, Offset position, String text, double scale) {
    // Configurar el estilo del texto (más pequeño)
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11.0 * scale, // Reducido de 14.0 a 11.0
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 2.0,
        ),
      ],
    );
    
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Calcular el padding alrededor del texto (más pequeño)
    final padding = 5.0 * scale; // Reducido de 8.0 a 5.0
    final labelWidth = textPainter.width + (padding * 2);
    final labelHeight = textPainter.height + (padding * 2);
    
    // Posición de la etiqueta (arriba del marcador)
    final labelX = position.dx - (labelWidth / 2);
    final labelY = position.dy - 10.0 * scale - labelHeight - 8.0 * scale;
    
    // Dibujar fondo redondeado (más pequeño)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      Radius.circular(4.0 * scale), // Reducido de 6.0 a 4.0
    );
    
    final backgroundPaint = Paint()
      ..color = const Color(0xFF00C853) // Verde para la etiqueta
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF00C853).withOpacity(0.8) // Verde para el borde de la etiqueta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    
    canvas.drawRRect(rect, backgroundPaint);
    canvas.drawRRect(rect, borderPaint);
    
    // Dibujar el texto
    textPainter.paint(canvas, Offset(labelX + padding, labelY + padding));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pathNodes.length < 2) {
      return;
    }

    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = routeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar líneas conectando los nodos en orden (transformando coordenadas)
    // Solo dibujar desde el último segmento completado en adelante
    final startIndex = completedSegmentsIndex + 1;
    
    for (int i = startIndex; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];

      final fromPoint = _transformPoint(from.x, from.y, size);
      final toPoint = _transformPoint(to.x, to.y, size);

      // Si es el segmento actual donde está el marcador, dibujar solo desde el marcador hasta el siguiente nodo
      if (i == completedSegmentsIndex + 1 && markerX != null && markerY != null) {
        final markerPoint = _transformPoint(markerX!, markerY!, size);
        // Dibujar solo desde el marcador hasta el siguiente nodo
        canvas.drawLine(markerPoint, toPoint, routePaint);
      } else {
        // Dibujar el segmento completo
        canvas.drawLine(fromPoint, toPoint, routePaint);
      }
    }

    // Dibujar nodo inicial (entrada) en azul si está disponible
    final startNode = entranceNode ?? pathNodes.first;
    final startPoint = _transformPoint(startNode.x, startNode.y, size);
    
    // Usar startNodeRadius si está definido, sino usar valores por defecto
    final startRadius = startNodeRadius ?? 8.0;
    final startRingRadius = startNodeRadius != null ? (startNodeRadius! * 1.5) : 12.0;
    
    final startPaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.fill;
    
    final startBorderPaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Anillo exterior para mayor visibilidad
    final ringPaint = Paint()
      ..color = routeColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(startPoint, startRingRadius, ringPaint);
    canvas.drawCircle(startPoint, startRadius, startPaint);
    canvas.drawCircle(startPoint, startRadius, startBorderPaint);

    // Dibujar nodo destino resaltado (celeste)
    if (pathNodes.isNotEmpty) {
      final destination = pathNodes.last;
      final destPoint = _transformPoint(destination.x, destination.y, size);
      
      // Calcular escala para la etiqueta (basada en el zoom actual)
      final scaleX = size.width / svgWidth;
      final scaleY = size.height / svgHeight;
      final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.5, 2.0); // Limitar escala
      
      final destPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.fill;
      
      final destBorderPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Usar destinationNodeRadius si está definido, sino usar valores por defecto
      final destRadius = destinationNodeRadius ?? 10.0;
      final destRingRadius = destinationNodeRadius != null ? (destinationNodeRadius! * 1.5) : 15.0;
      
      // Anillo exterior para mayor visibilidad
      final ringPaint = Paint()
        ..color = destinationColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(destPoint, destRingRadius, ringPaint);
      canvas.drawCircle(destPoint, destRadius, destPaint);
      canvas.drawCircle(destPoint, destRadius, destBorderPaint);
      
      // Dibujar etiqueta con el nombre del salón
      final salonName = _extractSalonName(destination);
      if (salonName != null && salonName.isNotEmpty) {
        _drawLabel(canvas, destPoint, salonName, scale);
      }
    }

    // Dibujar marcador del usuario
    if (markerX != null && markerY != null) {
      final markerPoint = _transformPoint(markerX!, markerY!, size);
      
      // Guardar el estado del canvas para poder rotar
      canvas.save();
      
      // Mover el origen al punto del marcador
      canvas.translate(markerPoint.dx, markerPoint.dy);
      
      // Rotar según el heading del sensor (si está disponible)
      if (markerHeading != null) {
        canvas.rotate(markerHeading!);
      }
      
      // Dibujar círculo del marcador (fondo azul)
      final markerBgPaint = Paint()
        ..color = const Color(0xFF1B38E3)
        ..style = PaintingStyle.fill;
      
      final markerBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final markerShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      // Sombra
      canvas.drawCircle(Offset.zero, 9.0, markerShadowPaint);
      
      // Círculo de fondo
      canvas.drawCircle(Offset.zero, 8.0, markerBgPaint);
      canvas.drawCircle(Offset.zero, 8.0, markerBorderPaint);
      
      // Dibujar flecha blanca apuntando hacia arriba (norte = 0°)
      final arrowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final arrowPath = Path();
      final arrowSize = 4.5;
      
      // Punto superior (punta de la flecha)
      arrowPath.moveTo(0, -arrowSize);
      // Punto inferior izquierdo
      arrowPath.lineTo(-arrowSize * 0.6, arrowSize * 0.3);
      // Punto inferior derecho
      arrowPath.lineTo(arrowSize * 0.6, arrowSize * 0.3);
      arrowPath.close();
      
      canvas.drawPath(arrowPath, arrowPaint);
      
      // Restaurar el estado del canvas
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MapRoutePainter oldDelegate) {
    return oldDelegate.pathNodes != pathNodes ||
        oldDelegate.entranceNode != entranceNode ||
        oldDelegate.markerX != markerX ||
        oldDelegate.markerY != markerY ||
        oldDelegate.nearestNodeIndex != nearestNodeIndex ||
        oldDelegate.markerHeading != markerHeading ||
        oldDelegate.completedSegmentsIndex != completedSegmentsIndex ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.destinationColor != destinationColor ||
        oldDelegate.routeWidth != routeWidth ||
        oldDelegate.svgWidth != svgWidth ||
        oldDelegate.svgHeight != svgHeight ||
        oldDelegate.destinationSalonName != destinationSalonName ||
        oldDelegate.startNodeRadius != startNodeRadius ||
        oldDelegate.destinationNodeRadius != destinationNodeRadius;
  }
}

