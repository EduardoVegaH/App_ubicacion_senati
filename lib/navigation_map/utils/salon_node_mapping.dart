/// Mapeo manual entre salones y nodos del mapa
/// Este archivo contiene las relaciones entre IDs de salones y IDs de nodos
class SalonNodeMapping {
  /// Mapeo de salones a nodos por piso
  /// Formato: {piso: {salonId: nodeId}}
  static const Map<int, Map<String, String>> _mappings = {
    // Piso 1 (mapa exterior)
    1: {
      // Ejemplo: 'salon-A-101': 'node_01',
      // Agregar más mapeos según sea necesario
    },
    
    // Piso 2 (mapa interior)
    2: {
      // Mapeo de salones numerados por torre (A-200, A-201, A-202, etc.)
      // Torre A - Salones 200-299
      'salon-A-200': 'node33',
      'salon-A-201': 'node34',
      'salon-A-202': 'node33',
      'salon-A-203': 'node35',
      'salon-A-204': 'node36',
      'salon-A-205': 'node17',
      'salon-A-206': 'node18',
      'salon-A-207': 'node19',
      
      // Torre B - Salones 200-299
      'salon-B-200': 'node15',
      'salon-B-201': 'node14',
      'salon-B-202': 'node16',
      'salon-B-203': 'node13',
      'salon-B-204': 'node12',
      'salon-B-205': 'node11',
      'salon-B-206': 'node10',
      'salon-B-207': 'node09',
      
      // Torre C - Salones 200-299
      'salon-C-200': 'node13', // Cerca de (1676, 1052) - dentro del área del salón
      'salon-C-201': 'node13', // Cerca de (1676, 1052) - dentro del área del salón C-201
      'salon-C-202': 'node12', // Cerca de (1598, 1052)
      'salon-C-203': 'node04',
      'salon-C-204': 'node03',
      'salon-C-205': 'node02',
      'salon-C-206': 'node08',
      
      // Mapeos adicionales para salones 100-199 (si se necesitan)
      'salon-A-101': 'node19',
      'salon-A-102': 'node18',
      'salon-A-103': 'node17',
      'salon-B-101': 'node23',
      'salon-B-102': 'node24',
      'salon-B-103': 'node25',
      'salon-C-101': 'node02',
      'salon-C-102': 'node03',
      'salon-C-103': 'node04',
    },
  };

  /// Obtiene el ID del nodo asociado a un salón
  static String? getNodeIdForSalon({
    required int piso,
    required String salonId,
  }) {
    final pisoMappings = _mappings[piso];
    if (pisoMappings == null) {
      print('⚠️ [SalonNodeMapping] No hay mapeos para piso $piso');
      return null;
    }
    
    print('🔍 [SalonNodeMapping] Buscando: $salonId en piso $piso');
    print('📋 Mapeos disponibles: ${pisoMappings.keys.take(5).join(", ")}...');
    
    // Normalizar el salonId (quitar espacios, convertir a minúsculas)
    final normalizedInput = salonId.toLowerCase().trim();
    
    // Buscar exacto primero
    if (pisoMappings.containsKey(salonId)) {
      print('✅ [SalonNodeMapping] Coincidencia exacta: $salonId -> ${pisoMappings[salonId]}');
      return pisoMappings[salonId];
    }
    
    // Buscar con formato normalizado
    if (pisoMappings.containsKey(normalizedInput)) {
      print('✅ [SalonNodeMapping] Coincidencia normalizada: $normalizedInput -> ${pisoMappings[normalizedInput]}');
      return pisoMappings[normalizedInput];
    }
    
    // Buscar variaciones del ID
    // Ej: "salon-A-604" también buscar "A-604", "604", etc.
    for (final entry in pisoMappings.entries) {
      final key = entry.key.toLowerCase();
      // Coincidencia parcial: si el input contiene la key o viceversa
      if (key.contains(normalizedInput) || normalizedInput.contains(key)) {
        print('✅ [SalonNodeMapping] Coincidencia parcial: $salonId -> ${entry.value} (key: $key)');
        return entry.value;
      }
    }
    
    // Buscar por número del salón
    final salonNumber = salonId.replaceAll(RegExp(r'[^0-9]'), '');
    if (salonNumber.isNotEmpty) {
      print('🔍 [SalonNodeMapping] Buscando por número: $salonNumber');
      for (final entry in pisoMappings.entries) {
        final keyNumber = entry.key.replaceAll(RegExp(r'[^0-9]'), '');
        if (keyNumber == salonNumber) {
          print('✅ [SalonNodeMapping] Coincidencia por número exacto: $salonNumber -> ${entry.value}');
          return entry.value;
        }
        // También buscar por últimos 2 dígitos
        if (salonNumber.length >= 2 && keyNumber.length >= 2) {
          final lastTwoInput = salonNumber.substring(salonNumber.length - 2);
          final lastTwoKey = keyNumber.substring(keyNumber.length - 2);
          if (lastTwoInput == lastTwoKey) {
            print('✅ [SalonNodeMapping] Coincidencia por últimos 2 dígitos: $lastTwoInput -> ${entry.value}');
            return entry.value;
          }
        }
      }
    }
    
    print('❌ [SalonNodeMapping] No se encontró mapeo para: $salonId');
    return null;
  }

  /// Obtiene todos los mapeos de un piso
  static Map<String, String>? getMappingsForFloor(int piso) {
    return _mappings[piso];
  }

  /// Agrega un mapeo manual (útil para actualizaciones dinámicas)
  static void addMapping({
    required int piso,
    required String salonId,
    required String nodeId,
  }) {
    // Nota: Esto no modifica el mapa estático, pero puedes usar esto
    // para crear un sistema dinámico si lo necesitas
    print('💡 Mapeo: Piso $piso, Salón $salonId -> Nodo $nodeId');
  }

  /// Mapea salones comunes que se usan en los cursos pero no existen en el SVG
  /// Retorna un mapeo de fallback
  static String? getFallbackNodeForSalon({
    required int piso,
    required String salonId,
  }) {
    final salonNumber = salonId.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Mapeos de fallback específicos
    if (piso == 2) {
      // Salón 604 -> usar node33 (cerca de salón 202/room02)
      // Este es el mapeo principal: 604 -> 202
      if (salonNumber == '604') {
        return 'node33'; // node33 está cerca de room02 (salón 202)
      }
      // Salón 200 -> usar node15
      if (salonNumber == '200') {
        return 'node15';
      }
      // Salones 6XX (600-699) -> mapear a node33 (202)
      if (salonNumber.startsWith('6') && salonNumber.length == 3) {
        return 'node33';
      }
      // Otros salones de 3 dígitos -> usar nodo basado en últimos 2 dígitos
      if (salonNumber.length >= 2) {
        final lastTwo = salonNumber.substring(salonNumber.length - 2);
        final nodeNum = int.tryParse(lastTwo);
        if (nodeNum != null && nodeNum <= 37) {
          return 'node${nodeNum.toString().padLeft(2, '0')}';
        }
      }
    }
    
    return null;
  }
}

