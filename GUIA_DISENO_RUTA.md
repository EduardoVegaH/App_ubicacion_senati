# 📐 GUÍA COMPLETA: Cómo Cambiar el Diseño de la Ruta

## 🎨 Opciones de Personalización Disponibles

### 1️⃣ **Color de la Ruta**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_navigator_screen.dart` (línea 593)
- `lib/features/navigation/presentation/widgets/map_canvas.dart` (línea 143)

#### Cambio:
```dart
// ACTUAL:
routeColor: const Color(0xFF1B38E3),  // Azul

// OPCIONES:
routeColor: Colors.red,                    // Rojo
routeColor: Colors.green,                  // Verde
routeColor: Colors.orange,                 // Naranja
routeColor: Colors.purple,                 // Morado
routeColor: Colors.teal,                   // Verde azulado

// Colores personalizados (hex):
routeColor: const Color(0xFFFF6B35),       // Naranja brillante
routeColor: const Color(0xFF4ECDC4),       // Turquesa
routeColor: const Color(0xFF2ECC71),       // Verde esmeralda
routeColor: const Color(0xFFE74C3C),       // Rojo coral

// Color con opacidad (semi-transparente):
routeColor: const Color(0xFF1B38E3).withOpacity(0.7),
routeColor: Colors.blue.withOpacity(0.5),  // 50% transparente

// Color desde RGB:
routeColor: Color.fromRGBO(255, 107, 53, 1.0),
```

---

### 2️⃣ **Grosor de la Línea**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_navigator_screen.dart` (línea 594)
  - Propiedad: `routeStrokeWidth`
- `lib/features/navigation/presentation/widgets/map_canvas.dart` (línea 144)
  - Propiedad: `routeWidth`

#### Cambio:
```dart
// Muy delgada
routeStrokeWidth: 1.0,

// Delgada
routeStrokeWidth: 2.0,

// Media (actual en map_navigator_screen)
routeStrokeWidth: 3.0,

// Gruesa
routeStrokeWidth: 5.0,

// Muy gruesa
routeStrokeWidth: 8.0,

// Extra gruesa
routeStrokeWidth: 12.0,
```

---

### 3️⃣ **Estilo de Extremos y Uniones**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_overlay_painter.dart` (líneas 198-199)
- `lib/features/navigation/presentation/widgets/map_route_painter.dart` (líneas 169-170)

#### Código actual:
```dart
final routePaint = Paint()
  ..color = routeColor
  ..style = PaintingStyle.stroke
  ..strokeWidth = routeStrokeWidth
  ..strokeCap = StrokeCap.round      // ← Cambiar aquí
  ..strokeJoin = StrokeJoin.round;   // ← Cambiar aquí
```

#### Opciones de extremos (StrokeCap):
```dart
..strokeCap = StrokeCap.round,   // Redondeado (suave) ✓ Recomendado
..strokeCap = StrokeCap.square,  // Cuadrado (extendido)
..strokeCap = StrokeCap.butt,    // Recto (sin extensión)
```

#### Opciones de uniones (StrokeJoin):
```dart
..strokeJoin = StrokeJoin.round, // Redondeado (suave) ✓ Recomendado
..strokeJoin = StrokeJoin.miter, // Pico agudo (ángulo)
..strokeJoin = StrokeJoin.bevel, // Biselado (cortado en ángulo)
```

---

### 4️⃣ **Línea Punteada o Discontinua**

#### Para hacer la línea punteada, modificar en los painters:

**En `map_overlay_painter.dart` (después de la línea 199):**
```dart
final routePaint = Paint()
  ..color = routeColor
  ..style = PaintingStyle.stroke
  ..strokeWidth = routeStrokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// AGREGAR ESTO PARA LÍNEA PUNTEADA:
final dashPattern = [5.0, 5.0]; // [longitud del trazo, longitud del espacio]
```

**Luego, en lugar de `canvas.drawPath(path, routePaint)`, usar:**
```dart
// Crear un path con patrón de guiones
final dashedPath = _createDashedPath(path, dashPattern);
canvas.drawPath(dashedPath, routePaint);
```

**Y agregar este método auxiliar:**
```dart
Path _createDashedPath(Path path, List<double> dashPattern) {
  final dashPath = Path();
  final pathMetrics = path.computeMetrics();
  
  for (final pathMetric in pathMetrics) {
    double distance = 0.0;
    while (distance < pathMetric.length) {
      final length = dashPattern[distance % dashPattern.length == 0 ? 0 : 1];
      final extractPath = pathMetric.extractPath(distance, distance + length);
      dashPath.addPath(extractPath, Offset.zero);
      distance += length;
    }
  }
  return dashPath;
}
```

**Patrones de línea discontinua comunes:**
```dart
[5.0, 5.0]    // Puntos cortos
[10.0, 5.0]   // Trazos largos
[15.0, 10.0]  // Trazos muy largos
[3.0, 3.0]    // Puntos pequeños
```

---

### 5️⃣ **Color del Nodo de Inicio (Entrada)**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_overlay_painter.dart` (línea 232)

#### Actual:
```dart
final entrancePaint = Paint()
  ..color = routeColor  // Mismo color que la ruta
```

#### Cambio:
```dart
final entrancePaint = Paint()
  ..color = Colors.green,  // Verde para el punto de inicio
  // o
  ..color = routeColor.withOpacity(0.8),  // Mismo color pero más suave
```

---

### 6️⃣ **Color del Nodo de Destino**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_navigator_screen.dart` (línea 596)
- `lib/features/navigation/presentation/widgets/map_canvas.dart` (línea 145)

#### Actual:
```dart
destinationColor: const Color(0xFF87CEEB),  // Celeste claro
```

#### Cambio:
```dart
destinationColor: Colors.green,        // Verde
destinationColor: Colors.red,          // Rojo
destinationColor: Colors.orange,       // Naranja
destinationColor: const Color(0xFFFF6B35),  // Naranja personalizado
```

---

### 7️⃣ **Tamaño del Radio de los Nodos**

#### Ubicación:
- `assets/lib_ext/navigation_map/ui/map_navigator_screen.dart` (línea 595)

#### Actual:
```dart
nodeRadius: 2.0,
```

#### Cambio:
```dart
nodeRadius: 3.0,   // Pequeño
nodeRadius: 5.0,   // Medio
nodeRadius: 8.0,   // Grande
nodeRadius: 10.0,  // Muy grande
```

---

## 🎯 Ejemplos de Combinaciones de Diseño

### Diseño Minimalista (línea delgada y suave):
```dart
routeColor: Colors.blue,
routeStrokeWidth: 1.5,
nodeRadius: 3.0,
destinationColor: Colors.blue.withOpacity(0.7),
```

### Diseño Llamativo (línea gruesa y colores vibrantes):
```dart
routeColor: Colors.orange,
routeStrokeWidth: 6.0,
nodeRadius: 8.0,
destinationColor: Colors.red,
```

### Diseño Profesional (azul oscuro):
```dart
routeColor: const Color(0xFF1A237E),  // Azul oscuro
routeStrokeWidth: 3.0,
nodeRadius: 5.0,
destinationColor: const Color(0xFF3F51B5),  // Azul medio
```

### Diseño Subtle (línea semi-transparente):
```dart
routeColor: Colors.blue.withOpacity(0.5),
routeStrokeWidth: 2.0,
nodeRadius: 4.0,
destinationColor: Colors.blue.withOpacity(0.7),
```

---

## 📝 Archivos a Modificar

1. **Para la implementación antigua:**
   - `assets/lib_ext/navigation_map/ui/map_navigator_screen.dart`
   - `assets/lib_ext/navigation_map/ui/map_overlay_painter.dart`

2. **Para la implementación nueva:**
   - `lib/features/navigation/presentation/widgets/map_canvas.dart`
   - `lib/features/navigation/presentation/widgets/map_route_painter.dart`

---

## ⚠️ Notas Importantes

- Los cambios en `map_navigator_screen.dart` afectan solo a esa pantalla específica
- Los cambios en `map_canvas.dart` afectan a la nueva implementación
- Si quieres que ambos tengan el mismo diseño, modifica ambos archivos
- Después de hacer cambios, ejecuta hot reload para ver los efectos inmediatamente

---

## 🚀 Cambios Rápidos Recomendados

### Hacer la línea más delgada:
```dart
routeStrokeWidth: 1.5,  // En map_navigator_screen.dart
routeWidth: 2.0,        // En map_canvas.dart
```

### Cambiar a color verde:
```dart
routeColor: Colors.green,
```

### Hacer puntos más pequeños:
```dart
nodeRadius: 3.0,
```

### Color de destino más llamativo:
```dart
destinationColor: Colors.red,
```

