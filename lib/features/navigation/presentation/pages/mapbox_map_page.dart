import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Pantalla que muestra el mapa de Mapbox con el estilo personalizado de SENATI
class MapboxMapPage extends StatefulWidget {
  const MapboxMapPage({super.key});

  @override
  State<MapboxMapPage> createState() => _MapboxMapPageState();
}

class _MapboxMapPageState extends State<MapboxMapPage> {
  MapboxMap? mapboxMap;
  bool _isMapReady = false;
  

  // Configuración del mapa
  static const String _mapboxAccessToken =
      "pk.eyJ1IjoiaGVybmFuZHpqMjAwNCIsImEiOiJjbWlpM25oZHowZDN0M2RwenV0OW9tenN3In0.XnovWmQLqfX5Sl-Nt8kP5w";
  // Style URL del mapa de tu compañero (con /draft - estilo en desarrollo)
  static const String _styleURL =
      "mapbox://styles/hernandzj2004/cmiihcv9c002p01s717k52aa4/draft";

  // Coordenadas del centro del campus SENATI INDEPENDENCIA (calculadas del polígono del campus)
  static const double _senatiLatitude = -11.999;  // Centro del campus
  static const double _senatiLongitude = -77.060; // Centro del campus

  @override
  void initState() {
    super.initState();
    // Configurar el access token de Mapbox
    MapboxOptions.setAccessToken(_mapboxAccessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa SENATI'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Widget del mapa de Mapbox
          MapWidget(
            key: const ValueKey("mapboxMapWidget"),
            onMapCreated: _onMapCreated,
          ),
          // Indicador de carga mientras el mapa se inicializa
          if (!_isMapReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  /// Callback cuando el mapa se crea
  void _onMapCreated(MapboxMap controller) {
    setState(() {
      mapboxMap = controller;
    });

    // Cargar el estilo INMEDIATAMENTE - esto es crítico para mostrar el mapa correcto
    print("🗺️ Cargando estilo del mapa: $_styleURL");
    print("🔑 Usando access token: ${_mapboxAccessToken.substring(0, 20)}...");
    
    // IMPORTANTE: Cargar el estilo ANTES de que el mapa muestre cualquier cosa
    // Usar microtask para asegurar que se ejecute lo antes posible
    Future.microtask(() async {
      if (!mounted || mapboxMap == null) return;
      
      try {
        // Cargar el estilo personalizado de SENATI (con /draft)
        await mapboxMap!.style.setStyleURI(_styleURL);
        print("✅ Estilo del mapa cargado correctamente");
        
        // Verificar que el estilo se cargó correctamente
        final loadedStyleURI = await mapboxMap!.style.getStyleURI();
        print("📋 Estilo actual del mapa: $loadedStyleURI");
        
        if (loadedStyleURI.contains("cmiihcv9c002p01s717k52aa4")) {
          print("✅ Confirmado: Estilo correcto cargado (con rutas y nodos)");
        } else {
          print("⚠️ ADVERTENCIA: El estilo cargado NO coincide con el esperado");
          print("   Esperado: $_styleURL");
          print("   Obtenido: $loadedStyleURI");
        }
        
        // Esperar a que el estilo se renderice completamente
        await Future.delayed(const Duration(milliseconds: 1000));
        
        if (!mounted) return;
        
        // 1. Ocultar las capas de rutas y nodos del estilo original
        await _hideExistingLayers();
        
        // 2. Centrar el mapa en SENATI
        _centerMapOnSenati();
        setState(() {
          _isMapReady = true;
        });
      } catch (error) {
        print("❌ Error cargando estilo del mapa: $error");
        print("🔍 Detalles del error: ${error.toString()}");
        print("📝 Verifica que:");
        print("  1. El access token tenga permisos para acceder al estilo");
        print("  2. El estilo esté publicado o compartido correctamente");
        print("  3. La URL del estilo sea correcta: $_styleURL");
        print("  4. El estilo no esté en modo privado");
        
        // Intentar sin /draft como fallback
        final styleURLWithoutDraft = _styleURL.replaceAll('/draft', '');
        print("🔄 Intentando sin /draft: $styleURLWithoutDraft");
        
        try {
          await mapboxMap!.style.setStyleURI(styleURLWithoutDraft);
          print("✅ Estilo cargado sin /draft");
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          _centerMapOnSenati();
          setState(() {
            _isMapReady = true;
          });
        } catch (error2) {
          print("❌ Error persistente: $error2");
          _centerMapOnSenati();
          setState(() {
            _isMapReady = true;
          });
        }
      }
    });
  }

  /// Centra el mapa en las coordenadas de SENATI con animación
  void _centerMapOnSenati() {
    if (mapboxMap == null) return;

    mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(_senatiLongitude, _senatiLatitude),
        ),
        zoom: 16.5, // Zoom apropiado para ver el campus completo
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  /// Elimina todas las capas de rutas y nodos del estilo de Mapbox
  Future<void> _hideExistingLayers() async {
    if (mapboxMap == null) return;
    
    try {
      print("🗑️ Eliminando todas las rutas y nodos del estilo de Mapbox...");
      
      // Intentar obtener todas las capas del estilo
      try {
        final allLayers = await mapboxMap!.style.getStyleLayers();
        print("📋 Encontradas ${allLayers.length} capas en el estilo");
        
        int removedCount = 0;
        
        // Eliminar todas las capas que sean de tipo línea o círculo
        for (final layer in allLayers) {
          // Verificar que layer no sea null
          if (layer == null) continue;
          
          final layerId = layer.id;
          final layerType = layer.type;
          
          // Verificar que id y type no sean null
          if (layerId == null || layerType == null) continue;
          
          // Verificar si es una capa de línea o círculo
          if (layerType == 'line' || layerType == 'circle' || 
              layerType == 'symbol' || layerType == 'fill') {
            // Verificar si el nombre sugiere que es una ruta o nodo
            // También eliminar las capas que creamos anteriormente
            final lowerId = layerId.toLowerCase();
            if (lowerId.contains('ruta') || lowerId.contains('nodo') ||
                lowerId.contains('route') || lowerId.contains('node') ||
                lowerId.contains('path') || lowerId.contains('line') ||
                lowerId.contains('circle') || lowerId.contains('waypoint') ||
                lowerId == 'route-layer' || lowerId == 'points-layer') {
              try {
                await mapboxMap!.style.removeStyleLayer(layerId);
                print("✅ Capa eliminada: $layerId (tipo: $layerType)");
                removedCount++;
              } catch (e) {
                print("⚠️ No se pudo eliminar capa $layerId: $e");
              }
            }
          }
        }
        
        print("✅ Eliminadas $removedCount capas de rutas y nodos");
      } catch (e) {
        print("⚠️ No se pudieron obtener las capas del estilo: $e");
        print("🔄 Intentando eliminar por nombres conocidos...");
        
        // Fallback: intentar eliminar por nombres conocidos
        final possibleLayerNames = [
          'ruta', 'nodo', 'route', 'node', 'path', 'routes', 'nodes',
          'line', 'circle', 'lines', 'circles', 'waypoints', 'waypoint',
          'Line', 'Circle', 'Routes', 'Nodes', 'Ruta', 'Nodo',
          'routes-layer', 'nodes-layer', 'ruta-layer', 'nodo-layer',
          'line-layer', 'circle-layer', 'path-layer'
        ];
        
        int removedCount = 0;
        for (final layerName in possibleLayerNames) {
          try {
            await mapboxMap!.style.removeStyleLayer(layerName);
            print("✅ Capa eliminada: $layerName");
            removedCount++;
          } catch (_) {}
        }
        
        // Eliminar sources relacionados (incluyendo los que creamos)
        final possibleSourceNames = [
          'ruta-source', 'nodes-source', 'route-source', 'node-source',
          'routes-source', 'paths-source', 'waypoints-source',
          'ruta', 'nodo', 'route', 'node', 'routes', 'nodes',
          'route-source', 'points-source' // Los que creamos anteriormente
        ];
        
        for (final sourceName in possibleSourceNames) {
          try {
            await mapboxMap!.style.removeStyleSource(sourceName);
            print("✅ Source eliminado: $sourceName");
            removedCount++;
          } catch (_) {}
        }
        
        print("✅ Eliminadas $removedCount capas/sources de rutas y nodos");
      }
    } catch (error) {
      print("❌ Error eliminando capas: $error");
    }
  }

}

