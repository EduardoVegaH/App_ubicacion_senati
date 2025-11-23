import 'package:flutter/material.dart';
import '../../domain/entities/map_node.dart';

/// CustomPainter que dibuja la ruta sobre el mapa
/// 
/// Dibuja líneas conectando los nodos en orden y marca el destino
class MapRoutePainter extends CustomPainter {
  final List<MapNode> pathNodes;
  final Color routeColor;
  final Color destinationColor;
  final double routeWidth;

  MapRoutePainter({
    required this.pathNodes,
    this.routeColor = const Color(0xFF0066FF),
    this.destinationColor = const Color(0xFF00AA00),
    this.routeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathNodes.length < 2) return;

    final paint = Paint()
      ..color = routeColor
      ..strokeWidth = routeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar líneas conectando los nodos en orden
    for (int i = 0; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];

      canvas.drawLine(
        Offset(from.x, from.y),
        Offset(to.x, to.y),
        paint,
      );
    }

    // Dibujar círculo especial para el último nodo (destino)
    if (pathNodes.isNotEmpty) {
      final destination = pathNodes.last;
      final destinationPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.fill;

      // Círculo más grande para el destino
      canvas.drawCircle(
        Offset(destination.x, destination.y),
        12.0,
        destinationPaint,
      );

      // Borde del círculo de destino
      final destinationBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(destination.x, destination.y),
        12.0,
        destinationBorderPaint,
      );
    }

    // Dibujar pequeños círculos en cada nodo intermedio
    final nodePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pathNodes.length - 1; i++) {
      final node = pathNodes[i];
      canvas.drawCircle(
        Offset(node.x, node.y),
        6.0,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(MapRoutePainter oldDelegate) {
    return oldDelegate.pathNodes != pathNodes ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.destinationColor != destinationColor ||
        oldDelegate.routeWidth != routeWidth;
  }
}

