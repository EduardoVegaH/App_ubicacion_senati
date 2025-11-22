import 'package:flutter/material.dart';
import '../../data/models/map_node_model.dart';
import '../../data/models/edge_model.dart';

/// CustomPainter que dibuja la ruta sobre el mapa SVG
/// Usa los shapes de los edges para dibujar solo el camino exacto a seguir
class MapOverlayPainter extends CustomPainter {
  /// Lista de edges que forman la ruta (cada edge tiene su shape)
  final List<EdgeModel> pathEdges;
  
  /// Nodo de inicio (entrada/ascensor)
  final MapNodeModel? entranceNode;
  
  /// Nodo de destino (para resaltar)
  final MapNodeModel? destinationNode;
  
  /// Nodo actual del usuario (para futuro movimiento en tiempo real)
  final MapNodeModel? currentUserNode;
  
  /// Color de la ruta
  final Color routeColor;
  
  /// Grosor de la línea de la ruta
  final double routeStrokeWidth;
  
  /// Radio de los nodos en la ruta
  final double nodeRadius;
  
  /// Color del nodo destino
  final Color destinationColor;
  
  /// Color del nodo actual del usuario
  final Color userNodeColor;
  
  /// Dimensiones del SVG (viewBox)
  final double svgWidth;
  final double svgHeight;

  const MapOverlayPainter({
    required this.pathEdges,
    this.entranceNode,
    this.destinationNode,
    this.currentUserNode,
    this.routeColor = const Color(0xFF1B38E3),
    this.routeStrokeWidth = 2.5,
    this.nodeRadius = 6.0,
    this.destinationColor = const Color(0xFF87CEEB),
    this.userNodeColor = Colors.red,
    this.svgWidth = 2117.0,
    this.svgHeight = 1729.0,
  });
  
  /// Transforma coordenadas del SVG a coordenadas del canvas
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
    if (pathEdges.isEmpty) return;

    // Configurar paint para la ruta
    final routePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = routeStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar cada edge usando su shape
    for (final edge in pathEdges) {
      if (edge.shape.isEmpty) {
        continue;
      }
      
      // Crear path desde el shape del edge
      final path = Path();
      bool isFirst = true;
      
      for (final point in edge.shape) {
        final transformedPoint = _transformPoint(point.dx, point.dy, size);
        if (isFirst) {
          path.moveTo(transformedPoint.dx, transformedPoint.dy);
          isFirst = false;
        } else {
          path.lineTo(transformedPoint.dx, transformedPoint.dy);
        }
      }
      
      // Dibujar el segmento
      canvas.drawPath(path, routePaint);
    }

    // Dibujar nodo inicial (entrada) en azul
    if (entranceNode != null) {
      final entrancePoint = _transformPoint(entranceNode!.x, entranceNode!.y, size);
      
      final entrancePaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.fill;
      
      final entranceBorderPaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      // Anillo exterior para mayor visibilidad
      final ringPaint = Paint()
        ..color = routeColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        entrancePoint,
        nodeRadius * 2.0,
        ringPaint,
      );
      
      // Círculo para el punto inicial
      canvas.drawCircle(
        entrancePoint,
        nodeRadius * 1.3,
        entrancePaint,
      );
      canvas.drawCircle(
        entrancePoint,
        nodeRadius * 1.3,
        entranceBorderPaint,
      );
    }

    // Dibujar nodo destino resaltado
    if (destinationNode != null) {
      final destPoint = _transformPoint(destinationNode!.x, destinationNode!.y, size);
      
      final destPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.fill;
      
      final destBorderPaint = Paint()
        ..color = destinationColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Anillo exterior para mayor visibilidad (primero)
      final ringPaint = Paint()
        ..color = destinationColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        destPoint,
        nodeRadius * 2.5,
        ringPaint,
      );
      
      // Círculo más grande para el destino
      canvas.drawCircle(
        destPoint,
        nodeRadius * 1.5,
        destPaint,
      );
      canvas.drawCircle(
        destPoint,
        nodeRadius * 1.5,
        destBorderPaint,
      );
    }

    // Dibujar nodo actual del usuario (preparado para futuro)
    if (currentUserNode != null) {
      final userPoint = _transformPoint(currentUserNode!.x, currentUserNode!.y, size);
      
      final userPaint = Paint()
        ..color = userNodeColor
        ..style = PaintingStyle.fill;
      
      final userBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      // Círculo para el usuario
      canvas.drawCircle(
        userPoint,
        nodeRadius * 1.2,
        userPaint,
      );
      canvas.drawCircle(
        userPoint,
        nodeRadius * 1.2,
        userBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(MapOverlayPainter oldDelegate) {
    return oldDelegate.pathEdges != pathEdges ||
        oldDelegate.entranceNode != entranceNode ||
        oldDelegate.destinationNode != destinationNode ||
        oldDelegate.currentUserNode != currentUserNode ||
        oldDelegate.routeColor != routeColor;
  }
}

