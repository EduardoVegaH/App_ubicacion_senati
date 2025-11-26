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

  @override
  void paint(Canvas canvas, Size size) {
    print('🎨 MapRoutePainter.paint: ${pathNodes.length} nodos, canvas size: ${size.width}x${size.height}');
    
    if (pathNodes.length < 2) {
      print('⚠️ MapRoutePainter: No hay suficientes nodos para dibujar (${pathNodes.length} < 2)');
      return;
    }
    
    print('🎨 MapRoutePainter: Dibujando ruta con ${pathNodes.length} nodos');

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
    
    canvas.drawCircle(startPoint, 12.0, ringPaint);
    canvas.drawCircle(startPoint, 8.0, startPaint);
    canvas.drawCircle(startPoint, 8.0, startBorderPaint);

    // Dibujar nodo destino resaltado (celeste)
    if (pathNodes.isNotEmpty) {
      final destination = pathNodes.last;
      final destPoint = _transformPoint(destination.x, destination.y, size);
      
      final destPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.fill;
      
      final destBorderPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Anillo exterior para mayor visibilidad
      final ringPaint = Paint()
        ..color = destinationColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(destPoint, 15.0, ringPaint);
      canvas.drawCircle(destPoint, 10.0, destPaint);
      canvas.drawCircle(destPoint, 10.0, destBorderPaint);
    }

    // Dibujar pequeños círculos en cada nodo intermedio
    final nodePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.fill;

    for (int i = 1; i < pathNodes.length - 1; i++) {
      final node = pathNodes[i];
      final nodePoint = _transformPoint(node.x, node.y, size);
      canvas.drawCircle(nodePoint, 4.0, nodePaint);
    }
    
    // Dibujar segmento dinámico desde marcador al nodo más cercano (si existe)
    if (markerX != null && markerY != null && nearestNodeIndex != null && nearestNodeIndex! >= 0 && nearestNodeIndex! < pathNodes.length) {
      final nearestNode = pathNodes[nearestNodeIndex!];
      final markerPoint = _transformPoint(markerX!, markerY!, size);
      final nearestNodePoint = _transformPoint(nearestNode.x, nearestNode.y, size);
      
      // Solo dibujar segmento si el marcador no está exactamente en el nodo
      final dx = markerX! - nearestNode.x;
      final dy = markerY! - nearestNode.y;
      final distanceToNode = (dx * dx + dy * dy);
      
      if (distanceToNode > 1.0) { // Si hay una distancia mínima (1 píxel)
        final dynamicSegmentPaint = Paint()
          ..color = routeColor.withOpacity(0.5)
          ..strokeWidth = routeWidth * 0.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        // Dibujar línea discontinua desde marcador al nodo más cercano
        final dashPattern = <double>[5, 5];
        final path = Path();
        path.moveTo(markerPoint.dx, markerPoint.dy);
        path.lineTo(nearestNodePoint.dx, nearestNodePoint.dy);
        canvas.drawPath(path, dynamicSegmentPaint);
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
        ..strokeWidth = 2.0; // Reducido
      
      final markerShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      // Sombra (reducida)
      canvas.drawCircle(Offset.zero, 9.0, markerShadowPaint);
      
      // Círculo de fondo (reducido)
      canvas.drawCircle(Offset.zero, 8.0, markerBgPaint);
      canvas.drawCircle(Offset.zero, 8.0, markerBorderPaint);
      
      // Dibujar flecha blanca apuntando hacia arriba (norte = 0°)
      final arrowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final arrowPath = Path();
      final arrowSize = 4.5; // Reducido
      
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
        oldDelegate.routeColor != routeColor ||
        oldDelegate.destinationColor != destinationColor ||
        oldDelegate.routeWidth != routeWidth ||
        oldDelegate.svgWidth != svgWidth ||
        oldDelegate.svgHeight != svgHeight;
  }
}

