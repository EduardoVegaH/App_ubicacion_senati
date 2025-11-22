import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter que dibuja una ruta como una línea continua sobre el mapa
/// Recibe una lista de puntos (x, y) y los conecta con una línea
class RutaPainter extends CustomPainter {
  /// Lista de puntos que forman la ruta
  /// Cada punto es un Offset con coordenadas (x, y)
  final List<Offset> puntos;
  
  /// Color de la línea de la ruta
  final Color color;
  
  /// Grosor de la línea
  final double strokeWidth;
  
  /// Color del relleno de los puntos (nodos)
  final Color? puntoColor;
  
  /// Radio de los puntos (nodos) en la ruta
  final double puntoRadio;
  
  /// Si se debe dibujar los puntos (nodos)
  final bool mostrarPuntos;
  
  /// Si se debe dibujar flechas indicando la dirección
  final bool mostrarFlechas;
  
  /// Color de las flechas
  final Color? flechaColor;

  const RutaPainter({
    required this.puntos,
    this.color = const Color(0xFF1B38E3),
    this.strokeWidth = 3.0,
    this.puntoColor,
    this.puntoRadio = 5.0,
    this.mostrarPuntos = true,
    this.mostrarFlechas = false,
    this.flechaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar la línea continua conectando todos los puntos
    if (puntos.length > 1) {
      final path = Path();
      path.moveTo(puntos[0].dx, puntos[0].dy);
      
      for (int i = 1; i < puntos.length; i++) {
        path.lineTo(puntos[i].dx, puntos[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Dibujar los puntos (nodos) si está habilitado
    if (mostrarPuntos && puntoRadio > 0) {
      final puntoPaint = Paint()
        ..color = puntoColor ?? color
        ..style = PaintingStyle.fill;

      final bordePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final punto in puntos) {
        // Dibujar círculo relleno
        canvas.drawCircle(punto, puntoRadio, puntoPaint);
        // Dibujar borde del círculo
        canvas.drawCircle(punto, puntoRadio, bordePaint);
      }
    }

    // Dibujar flechas indicando la dirección si está habilitado
    if (mostrarFlechas && puntos.length > 1) {
      final flechaPaint = Paint()
        ..color = flechaColor ?? color
        ..style = PaintingStyle.fill;

      for (int i = 0; i < puntos.length - 1; i++) {
        _dibujarFlecha(
          canvas,
          puntos[i],
          puntos[i + 1],
          flechaPaint,
        );
      }
    }
  }

  /// Dibuja una flecha entre dos puntos indicando la dirección
  void _dibujarFlecha(
    Canvas canvas,
    Offset inicio,
    Offset fin,
    Paint paint,
  ) {
    // Calcular el ángulo de la línea
    final dx = fin.dx - inicio.dx;
    final dy = fin.dy - inicio.dy;
    final angulo = math.atan2(dy, dx);

    // Tamaño de la flecha
    final largoFlecha = 12.0;
    final anchoFlecha = 8.0;

    // Calcular el punto donde termina la línea (antes del final para que la flecha no se superponga)
    final distancia = (dx * dx + dy * dy);
    final distanciaNormalizada = distancia > 0 ? distancia : 1.0;
    final factor = (distanciaNormalizada - largoFlecha) / distanciaNormalizada;
    final puntoFlecha = Offset(
      inicio.dx + dx * factor,
      inicio.dy + dy * factor,
    );

    // Crear el path de la flecha
    final path = Path();
    
    // Punto de la punta de la flecha
    final punta = fin;
    
    // Puntos de la base de la flecha
    final base1 = Offset(
      puntoFlecha.dx + anchoFlecha * math.cos(angulo + 1.5708),
      puntoFlecha.dy + anchoFlecha * math.sin(angulo + 1.5708),
    );
    
    final base2 = Offset(
      puntoFlecha.dx + anchoFlecha * math.cos(angulo - 1.5708),
      puntoFlecha.dy + anchoFlecha * math.sin(angulo - 1.5708),
    );

    // Dibujar el triángulo de la flecha
    path.moveTo(punta.dx, punta.dy);
    path.lineTo(base1.dx, base1.dy);
    path.lineTo(base2.dx, base2.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RutaPainter oldDelegate) {
    return oldDelegate.puntos != puntos ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.puntoColor != puntoColor ||
        oldDelegate.puntoRadio != puntoRadio ||
        oldDelegate.mostrarPuntos != mostrarPuntos ||
        oldDelegate.mostrarFlechas != mostrarFlechas ||
        oldDelegate.flechaColor != flechaColor;
  }
}

/// Extensión para convertir List<NodoMapa> a List<Offset>
extension NodoMapaToOffset on List {
  /// Convierte una lista de NodoMapa a una lista de Offset
  /// Útil para usar con RutaPainter
  static List<Offset> fromNodos(List<dynamic> nodos) {
    return nodos.map((nodo) {
      // Asumimos que el nodo tiene propiedades x e y
      final x = nodo.x is double ? nodo.x : (nodo.x as num).toDouble();
      final y = nodo.y is double ? nodo.y : (nodo.y as num).toDouble();
      return Offset(x, y);
    }).toList();
  }
}

