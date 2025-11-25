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

  MapRoutePainter({
    required this.pathNodes,
    this.entranceNode,
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
    for (int i = 0; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];

      final fromPoint = _transformPoint(from.x, from.y, size);
      final toPoint = _transformPoint(to.x, to.y, size);

      canvas.drawLine(fromPoint, toPoint, routePaint);
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
  }

  @override
  bool shouldRepaint(MapRoutePainter oldDelegate) {
    return oldDelegate.pathNodes != pathNodes ||
        oldDelegate.entranceNode != entranceNode ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.destinationColor != destinationColor ||
        oldDelegate.routeWidth != routeWidth ||
        oldDelegate.svgWidth != svgWidth ||
        oldDelegate.svgHeight != svgHeight;
  }
}

