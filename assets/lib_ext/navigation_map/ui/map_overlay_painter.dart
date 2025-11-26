import 'package:flutter/material.dart';
import '../models/map_node.dart';
import '../models/edge.dart';

/// CustomPainter que dibuja la ruta sobre el mapa SVG
/// Usa los shapes de los edges para dibujar solo el camino exacto a seguir
class MapOverlayPainter extends CustomPainter {
  /// Lista de edges que forman la ruta (cada edge tiene su shape)
  final List<Edge> pathEdges;
  
  /// Nodo de inicio (entrada/ascensor)
  final MapNode? entranceNode;
  
  /// Nodo de destino (para resaltar)
  final MapNode? destinationNode;
  
  /// Nodo actual del usuario (para futuro movimiento en tiempo real)
  final MapNode? currentUserNode;
  
  /// Color de la ruta
  final Color routeColor;
  
  /// Grosor de la línea de la ruta
  final double routeStrokeWidth;
  
  /// Radio de los nodos en la ruta
  final double nodeRadius;
  
  /// Tamaño del punto de inicio (radio del círculo)
  final double? startNodeRadius;
  
  /// Tamaño del punto de destino (radio del círculo)
  final double? destinationNodeRadius;
  
  /// Color del nodo destino
  final Color destinationColor;
  
  /// Color del nodo actual del usuario
  final Color userNodeColor;
  
  /// Dimensiones del SVG (viewBox)
  final double svgWidth;
  final double svgHeight;
  
  /// Nombre del salón destino (para mostrar en la etiqueta)
  final String? destinationSalonName;

  const MapOverlayPainter({
    required this.pathEdges,
    this.entranceNode,
    this.destinationNode,
    this.currentUserNode,
    this.routeColor = const Color(0xFF1B38E3),
    this.routeStrokeWidth = 2.5, // Línea más delgada
    this.nodeRadius = 6.0,
    this.startNodeRadius,
    this.destinationNodeRadius,
    this.destinationColor = const Color(0xFF87CEEB), // Celeste claro (Sky Blue)
    this.userNodeColor = Colors.red,
    this.svgWidth = 2117.0, // viewBox width del SVG
    this.svgHeight = 1729.0, // viewBox height del SVG
    this.destinationSalonName,
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
  
  /// Extrae el nombre del salón o área desde el ID del nodo
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
    
    // Si el nodo tiene un salonId, usarlo
    if (node.salonId != null && node.salonId!.isNotEmpty) {
      final salonId = node.salonId!;
      // Limpiar prefijos comunes
      String cleanId = salonId.replaceFirst(RegExp(r'^salon-', caseSensitive: false), '');
      return 'Salón $cleanId';
    }
    
    return null;
  }
  
  /// Dibuja una etiqueta de texto con fondo
  void _drawLabel(Canvas canvas, Offset position, String text, double scale) {
r    // Configurar el estilo del texto (más pequeño)
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
    final labelY = position.dy - nodeRadius * 1.5 * scale - labelHeight - 8.0 * scale;
    
    // Dibujar fondo redondeado (más pequeño)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      Radius.circular(4.0 * scale), // Reducido de 6.0 a 4.0
    );
    
    final backgroundPaint = Paint()
      ..color = destinationColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = destinationColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    
    canvas.drawRRect(rect, backgroundPaint);
    canvas.drawRRect(rect, borderPaint);
    
    // Dibujar el texto
    textPainter.paint(canvas, Offset(labelX + padding, labelY + padding));
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
        // Fallback: si no hay shape, dibujar línea recta entre nodos
        // Esto no debería pasar si los edges se generaron correctamente
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
      
      // Usar startNodeRadius si está definido, sino usar nodeRadius como antes
      final startRadius = startNodeRadius ?? (nodeRadius * 1.3);
      final startRingRadius = startNodeRadius != null ? (startNodeRadius! * 1.5) : (nodeRadius * 2.0);
      
      final entrancePaint = Paint()
        ..color = routeColor // Azul igual que la ruta
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
        startRingRadius,
        ringPaint,
      );
      
      // Círculo para el punto inicial
      canvas.drawCircle(
        entrancePoint,
        startRadius,
        entrancePaint,
      );
      canvas.drawCircle(
        entrancePoint,
        startRadius,
        entranceBorderPaint,
      );
    }

    // Dibujar nodo destino resaltado
    if (destinationNode != null) {
      final destPoint = _transformPoint(destinationNode!.x, destinationNode!.y, size);
      
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
      
      // Usar destinationNodeRadius si está definido, sino usar nodeRadius como antes
      final destRadius = destinationNodeRadius ?? (nodeRadius * 1.5);
      final destRingRadius = destinationNodeRadius != null ? (destinationNodeRadius! * 1.7) : (nodeRadius * 2.5);
      
      // Anillo exterior para mayor visibilidad (primero)
      final ringPaint = Paint()
        ..color = destinationColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        destPoint,
        destRingRadius,
        ringPaint,
      );
      
      // Círculo más grande para el destino
      canvas.drawCircle(
        destPoint,
        destRadius,
        destPaint,
      );
      canvas.drawCircle(
        destPoint,
        destRadius,
        destBorderPaint,
      );
      
      // Dibujar etiqueta con el nombre del salón
      final salonName = _extractSalonName(destinationNode);
      if (salonName != null && salonName.isNotEmpty) {
        _drawLabel(canvas, destPoint, salonName, scale);
      }
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
        oldDelegate.routeColor != routeColor ||
        oldDelegate.destinationSalonName != destinationSalonName ||
        oldDelegate.startNodeRadius != startNodeRadius ||
        oldDelegate.destinationNodeRadius != destinationNodeRadius;
  }
}

