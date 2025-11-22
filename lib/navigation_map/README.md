# 🗺️ Sistema de Navegación Interna - Sprint 4 y 6

Sistema completo de navegación interna para la app SENATI que permite calcular rutas desde la entrada principal hasta cualquier salón usando el algoritmo A*.

## 📁 Estructura

```
lib/navigation_map/
├── models/
│   ├── map_node.dart          # Modelo de nodo del grafo
│   └── edge.dart              # Modelo de conexión entre nodos
├── parsers/
│   └── svg_node_parser.dart   # Parser para extraer nodos de SVG
├── services/
│   ├── graph_storage_service.dart    # Almacenamiento en Firestore
│   ├── edge_generator_service.dart   # Generación automática de edges
│   └── pathfinding_service.dart      # Algoritmo A*
├── repos/
│   └── graph_repository.dart         # Repositorio del grafo
├── ui/
│   ├── map_navigator_screen.dart     # Pantalla de navegación
│   └── map_overlay_painter.dart      # CustomPainter para dibujar rutas
└── utils/
    ├── graph_initializer.dart        # Inicializador del grafo
    └── salon_helper.dart             # Utilidades para salones
```

## 🚀 Inicialización

### Paso 1: Inicializar el grafo desde SVG

Antes de usar la navegación, debes inicializar el grafo parseando los SVG y guardando en Firestore:

```dart
import 'package:tu_app/navigation_map/utils/graph_initializer.dart';

final initializer = GraphInitializer();

// Inicializar todos los pisos
await initializer.initializeAllFloors(
  svgPaths: {
    1: 'assets/mapas/map_ext.svg',
    2: 'assets/mapas/map_int_piso2.svg',
  },
);
```

O desde la UI de administración:
- Abre el menú lateral
- Ve a "Administración de Grafo"
- Presiona "Inicializar Todos los Pisos"

### Paso 2: Usar la navegación

La navegación se integra automáticamente desde el botón "Navegar en Tiempo Real" en cada curso.

## 📊 Estructura de Firestore

```
/mapas
  /piso_1
    /nodes
      /node01 { id, x, y, piso, tipo, salonId }
      /node02 { ... }
      ...
    /edges
      /node01_node02 { fromId, toId, weight, piso, tipo }
      ...
  /piso_2
    /nodes { ... }
    /edges { ... }
```

## 🔧 Funcionalidades

### ✅ Implementado

- ✅ Parseo automático de nodos desde SVG
- ✅ Generación automática de conexiones (edges)
- ✅ Almacenamiento en Firestore por piso
- ✅ Algoritmo A* para encontrar camino más corto
- ✅ Pantalla de navegación con mapa SVG
- ✅ Dibujado de ruta sobre el mapa
- ✅ Resaltado del nodo destino
- ✅ Integración con botón "Navegar en Tiempo Real"
- ✅ Zoom y pan en el mapa

### 🔮 Preparado para futuro

- ✅ Estructura lista para movimiento en tiempo real
- ✅ Campo `currentUserNode` en MapOverlayPainter
- ✅ Sistema de actualización de posición del usuario

## 🎯 Uso

### Desde código

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MapNavigatorScreen(
      objetivoSalonId: 'salon-A-201',
      piso: 2,
      salonNombre: 'Torre A, Piso 2, Salón 201',
    ),
  ),
);
```

### Extraer información del salón

```dart
import 'package:tu_app/navigation_map/utils/salon_helper.dart';

final piso = SalonHelper.extractPisoFromLocation(
  course.locationDetail,
  course.locationCode,
);

final salonId = SalonHelper.extractSalonId(
  course.locationDetail,
  course.locationCode,
);
```

## 🔍 Algoritmo A*

El algoritmo A* encuentra el camino más corto considerando:
- **g(n)**: Distancia real desde el inicio hasta el nodo n
- **h(n)**: Heurística (distancia euclidiana desde n hasta el destino)
- **f(n) = g(n) + h(n)**: Función de evaluación

## 📝 Notas

- Los nodos se extraen automáticamente de los `<circle>` dentro del grupo `<g id="NODES">` en el SVG
- Las conexiones se generan automáticamente basándose en distancia (máximo 150px)
- El nodo de entrada se detecta automáticamente buscando nodos con tipo "entrada" o ID que contenga "entrada", "inicio", "punto-inicial"
- Si no se encuentra un nodo específico para un salón, se busca por coincidencia parcial

## 🛠️ Mantenimiento

### Agregar un nuevo piso

1. Agregar el SVG a `assets/mapas/`
2. Asegurarse de que tenga el grupo `<g id="NODES">` con los círculos
3. Inicializar desde GraphAdminScreen o código

### Modificar conexiones manualmente

Puedes editar las conexiones directamente en Firestore o usar `EdgeGeneratorService.generateManualEdges()` para conexiones específicas.

## 🐛 Troubleshooting

**Error: "No se encontraron nodos"**
- Verifica que el SVG tenga el grupo `<g id="NODES">`
- Verifica que los círculos tengan atributos `id`, `cx`, `cy`

**Error: "No se encontró ruta"**
- Verifica que existan edges conectando el nodo de entrada con el destino
- Puede ser necesario regenerar los edges o agregar conexiones manuales

**La ruta no se muestra**
- Verifica que el grafo esté inicializado en Firestore
- Verifica que el piso sea correcto
- Verifica que el ID del salón coincida con algún nodo

