import '../../domain/repositories/navigation_repository.dart';
import '../data_sources/svg_map_data_source.dart';
import '../repositories/navigation_repository_impl.dart';
import 'graph_initializer.dart';

/// Servicio para inicializar automáticamente los nodos y edges de navegación
/// 
/// Verifica si los datos existen en Firestore y los inicializa si es necesario
class NavigationAutoInitializer {
  final NavigationRepository repository;
  final SvgMapDataSource svgDataSource;
  final GraphInitializer graphInitializer;

  NavigationAutoInitializer({
    required this.repository,
    required this.svgDataSource,
    required this.graphInitializer,
  });

  /// Inicializa automáticamente los nodos y edges para todos los pisos
  /// 
  /// Verifica si los datos existen antes de inicializar
  /// Muestra logs detallados en la consola
  Future<void> initializeIfNeeded() async {
    print('🚀 ========================================');
    print('🚀 INICIALIZACIÓN AUTOMÁTICA DE NAVEGACIÓN');
    print('🚀 ========================================');
    
    final floors = [1, 2];
    
    for (final floor in floors) {
      print('');
      print('📊 Verificando piso $floor...');
      
      try {
        // Verificar si ya existen nodos en Firestore
        final existingNodes = await repository.getNodesForFloor(floor);
        
        if (existingNodes.isNotEmpty) {
          // Verificar si los nodos son del formato correcto
          // Para piso 1: deben tener IDs como node_puerta_main01, node_17, etc.
          // NO deben tener IDs como node_01, node_02, etc. (formato incorrecto)
          // Para piso 2: deben tener IDs como node#36_Escalera#torreA, node#37, etc.
          bool hasCorrectFormat;
          
          if (floor == 1) {
            // Para piso 1, verificar si tiene nodos con formato incorrecto (node_01, node_02, etc.)
            // Los nodos incorrectos son aquellos que empiezan con "node_0" seguido de un dígito
            final hasIncorrectFormat = existingNodes.any((n) => 
              RegExp(r'^node_0\d+$').hasMatch(n.id)
            );
            
            // Verificar si tiene el nodo del comedor (importante para las rutas)
            final hasComedorNode = existingNodes.any((n) => n.id.contains('comedor'));
            
            // También verificar si tiene al menos un nodo con formato correcto
            // Los nodos correctos son: node_puerta_*, node_bano_*, node_escalera_*, o node_XX donde XX > 10
            final hasCorrectFormatNode = existingNodes.any((n) {
              if (n.id.contains('node_puerta') || 
                  n.id.contains('node_bano') ||
                  n.id.contains('node_escalera') ||
                  n.id.contains('node_patiocomedor')) {
                return true;
              }
              // Verificar si es node_XX donde XX es un número > 10
              final match = RegExp(r'^node_(\d+)$').firstMatch(n.id);
              if (match != null) {
                final num = int.tryParse(match.group(1)!);
                return num != null && num > 10;
              }
              return false;
            });
            
            hasCorrectFormat = !hasIncorrectFormat && hasCorrectFormatNode && hasComedorNode;
            
            if (hasIncorrectFormat) {
              print('⚠️  Piso $floor: Detectados nodos con formato incorrecto (node_01, node_02, etc.)');
              print('   Ejemplos: ${existingNodes.take(5).map((n) => n.id).join(", ")}');
            }
            
            if (!hasComedorNode) {
              print('⚠️  Piso $floor: NO se encontró el nodo del comedor (node_puerta_comedor)');
              print('   Esto es crítico para las rutas al comedor. Re-inicializando...');
            }
            
            if (!hasCorrectFormat) {
              print('⚠️  Piso $floor: No se encontraron nodos con formato correcto o falta nodo del comedor');
              print('   Total nodos: ${existingNodes.length}');
              print('   Primeros 10 IDs: ${existingNodes.take(10).map((n) => n.id).join(", ")}');
            }
          } else {
            // Para piso 2, verificar si tiene el formato con #
            hasCorrectFormat = existingNodes.any((n) => n.id.contains('#'));
          }
          
          if (!hasCorrectFormat) {
            // Si los nodos no tienen el formato correcto o falta el nodo del comedor, re-inicializar desde SVG
            print('⚠️  Piso $floor: Tiene nodos con formato incorrecto o falta nodo importante, re-inicializando desde SVG...');
            await _initializeFloorFromSvg(floor);
            print('📝 Piso $floor: Inicializando edges...');
            await _initializeEdgesForFloor(floor);
          } else {
            print('✅ Piso $floor: Ya tiene ${existingNodes.length} nodos en Firestore');
            
            // Para piso 1, verificar específicamente si falta el nodo del comedor
            if (floor == 1) {
              final hasComedorNode = existingNodes.any((n) => n.id.contains('comedor'));
              if (!hasComedorNode) {
                print('⚠️  Piso $floor: Aunque tiene formato correcto, FALTA el nodo del comedor');
                print('   Re-inicializando desde SVG para incluir el nodo del comedor...');
                await _initializeFloorFromSvg(floor);
                print('📝 Piso $floor: Inicializando edges...');
                await _initializeEdgesForFloor(floor);
                continue;
              }
            }
            
            // Verificar si ya existen edges
            final existingEdges = await repository.getEdgesForFloor(floor);
            if (existingEdges.isNotEmpty) {
              print('✅ Piso $floor: Ya tiene ${existingEdges.length} edges en Firestore');
              print('⏭️  Piso $floor: Saltando inicialización (ya está completo)');
              continue;
            } else {
              print('⚠️  Piso $floor: Tiene nodos pero no edges, inicializando edges...');
              await _initializeEdgesForFloor(floor);
            }
          }
        } else {
          // No hay nodos, inicializar todo desde SVG
          print('📝 Piso $floor: No tiene nodos, inicializando desde SVG...');
          await _initializeFloorFromSvg(floor);
          print('📝 Piso $floor: Inicializando edges...');
          await _initializeEdgesForFloor(floor);
        }
      } catch (e, stackTrace) {
        print('❌ Error inicializando piso $floor: $e');
        print('Stack trace: $stackTrace');
        // Continuar con el siguiente piso aunque uno falle
      }
    }
    
    print('');
    print('✅ ========================================');
    print('✅ INICIALIZACIÓN AUTOMÁTICA COMPLETADA');
    print('✅ ========================================');
  }

  /// Inicializa los nodos de un piso desde el SVG
  Future<void> _initializeFloorFromSvg(int floor) async {
    print('  📂 Cargando SVG del piso $floor...');
    
    final svgAssetPath = floor == 1
        ? 'assets/mapas/MAP_PISO_1.svg'
        : 'assets/mapas/MAP_PISO_2.svg';
    
    print('  📂 Ruta SVG: $svgAssetPath');
    
    try {
      final mapFloor = await svgDataSource.buildFloorFromSvg(
        floor: floor,
        assetPath: svgAssetPath,
      );
      
      print('  ✅ SVG parseado: ${mapFloor.nodes.length} nodos encontrados');
      
      // Mostrar algunos ejemplos de nodos parseados
      if (mapFloor.nodes.isNotEmpty) {
        print('  📋 Ejemplos de nodos parseados:');
        for (var i = 0; i < (mapFloor.nodes.length > 5 ? 5 : mapFloor.nodes.length); i++) {
          final node = mapFloor.nodes[i];
          print('     - ${node.id} (${node.x.toStringAsFixed(1)}, ${node.y.toStringAsFixed(1)})');
        }
        if (mapFloor.nodes.length > 5) {
          print('     ... y ${mapFloor.nodes.length - 5} más');
        }
      }
      
      // Verificar que se parsearon nodos importantes
      if (floor == 1) {
        final comedorNode = mapFloor.nodes.where((n) => n.id.contains('comedor')).toList();
        final puertaMainNode = mapFloor.nodes.where((n) => n.id.contains('puerta_main01')).toList();
        final allPuertaNodes = mapFloor.nodes.where((n) => n.id.contains('puerta')).toList();
        print('  🔍 Verificación de nodos importantes parseados:');
        print('     - Nodos de comedor: ${comedorNode.length} (${comedorNode.map((n) => n.id).join(", ")})');
        print('     - Nodos de puerta main: ${puertaMainNode.length} (${puertaMainNode.map((n) => n.id).join(", ")})');
        print('     - Todos los nodos con "puerta": ${allPuertaNodes.length}');
        if (allPuertaNodes.isNotEmpty) {
          print('       IDs: ${allPuertaNodes.map((n) => n.id).join(", ")}');
        }
        
        if (comedorNode.isEmpty) {
          print('  ⚠️ ADVERTENCIA CRÍTICA: No se parseó el nodo del comedor del SVG!');
          print('     Esto significa que el parser de paths no está funcionando correctamente.');
          print('     El nodo debería estar en el SVG como: <path id="node_puerta_comedor" ...>');
        }
      }
      
      // Guardar en Firestore (reemplazando los existentes si hay)
      print('  💾 Guardando nodos en Firestore (reemplazando existentes)...');
      // Usar el repositorio con reemplazo
      if (repository is NavigationRepositoryImpl) {
        await (repository as NavigationRepositoryImpl).saveFloorGraphReplacing(mapFloor);
      } else {
        await repository.saveFloorGraph(mapFloor);
      }
      
      print('  ✅ Piso $floor: ${mapFloor.nodes.length} nodos guardados exitosamente');
      
      // Verificar que se guardaron correctamente
      final savedNodes = await repository.getNodesForFloor(floor);
      if (floor == 1) {
        final savedComedorNode = savedNodes.where((n) => n.id.contains('comedor')).toList();
        final savedPuertaMainNode = savedNodes.where((n) => n.id.contains('puerta_main01')).toList();
        print('  🔍 Verificación post-guardado:');
        print('     - Total nodos guardados: ${savedNodes.length}');
        print('     - Nodos de comedor guardados: ${savedComedorNode.length} (${savedComedorNode.map((n) => n.id).join(", ")})');
        print('     - Nodos de puerta main guardados: ${savedPuertaMainNode.length} (${savedPuertaMainNode.map((n) => n.id).join(", ")})');
        
        if (savedComedorNode.isEmpty) {
          print('  ❌ ERROR CRÍTICO: El nodo del comedor NO se guardó en Firestore!');
          print('     Esto impedirá que las rutas al comedor funcionen.');
        } else {
          print('  ✅ El nodo del comedor se guardó correctamente en Firestore');
        }
      }
    } catch (e) {
      print('  ❌ Error al inicializar piso $floor desde SVG: $e');
      rethrow;
    }
  }

  /// Inicializa los edges de un piso
  Future<void> _initializeEdgesForFloor(int floor) async {
    try {
      final edgesCount = await graphInitializer.initializeEdgesForFloor(floor);
      print('  ✅ Piso $floor: $edgesCount edges creados y guardados');
    } catch (e) {
      print('  ❌ Error al inicializar edges del piso $floor: $e');
      rethrow;
    }
  }

  /// Inicializa solo los nodos (sin edges) para un piso específico
  Future<void> initializeNodesForFloor(int floor) async {
    print('🚀 Inicializando nodos del piso $floor...');
    await _initializeFloorFromSvg(floor);
  }

  /// Inicializa solo los edges para un piso específico
  Future<void> initializeEdgesForFloor(int floor) async {
    print('🚀 Inicializando edges del piso $floor...');
    await _initializeEdgesForFloor(floor);
  }
}

