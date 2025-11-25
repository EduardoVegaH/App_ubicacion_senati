/// Utilidad para extraer información del destino desde el ID del nodo
/// 
/// Extrae la torre, número de salón y construye el nombre del archivo de imagen
class DestinationInfoExtractor {
  /// Extrae la torre desde el ID del nodo
  /// 
  /// Ejemplos:
  /// - "node#05_sal#B200" -> "B"
  /// - "node#34_sal#A200" -> "A"
  /// - "node_puerta_comedor" -> null
  static String? extractTower(String nodeId) {
    // Buscar patrón: sal#X donde X es la torre
    final match = RegExp(r'sal#([A-C])').firstMatch(nodeId);
    if (match != null) {
      return match.group(1);
    }
    
    // Buscar patrón alternativo: node-salon-X-XXX
    final altMatch = RegExp(r'salon-([A-C])-').firstMatch(nodeId);
    if (altMatch != null) {
      return altMatch.group(1);
    }
    
    return null;
  }

  /// Extrae el número del salón desde el ID del nodo
  /// 
  /// Ejemplos:
  /// - "node#05_sal#B200" -> "200"
  /// - "node#34_sal#A201" -> "201"
  static String? extractRoomNumber(String nodeId) {
    // Buscar patrón: sal#X### donde ### es el número
    final match = RegExp(r'sal#[A-C](\d+)').firstMatch(nodeId);
    if (match != null) {
      return match.group(1);
    }
    
    // Buscar patrón alternativo: salon-X-###
    final altMatch = RegExp(r'salon-[A-C]-(\d+)').firstMatch(nodeId);
    if (altMatch != null) {
      return altMatch.group(1);
    }
    
    // Buscar cualquier número de 3 dígitos al final
    final numberMatch = RegExp(r'(\d{3,})$').firstMatch(nodeId);
    if (numberMatch != null) {
      return numberMatch.group(1);
    }
    
    return null;
  }

  /// Construye el nombre del archivo de imagen basado en torre y número
  /// 
  /// Formato: "foto-salon-{torre}-{numero}.png"
  /// Ejemplo: "foto-salon-b-200.png"
  static String? buildImagePath(String? tower, String? roomNumber) {
    if (tower == null || roomNumber == null) {
      return null;
    }
    
    return 'assets/fotos/foto-salon-${tower.toLowerCase()}-$roomNumber.png';
  }

  /// Extrae información completa del destino desde el ID del nodo
  /// 
  /// Retorna un mapa con:
  /// - tower: String? (A, B, o C)
  /// - roomNumber: String? (número del salón)
  /// - imagePath: String? (ruta completa de la imagen)
  static Map<String, String?> extractDestinationInfo(String nodeId) {
    final tower = extractTower(nodeId);
    final roomNumber = extractRoomNumber(nodeId);
    final imagePath = buildImagePath(tower, roomNumber);
    
    return {
      'tower': tower,
      'roomNumber': roomNumber,
      'imagePath': imagePath,
    };
  }

  /// Construye el nombre legible del destino
  /// 
  /// Ejemplo: "Torre B, Piso 2, Salón 200"
  static String buildDestinationName(String? tower, String? roomNumber, int floor) {
    if (tower == null || roomNumber == null) {
      return 'Destino';
    }
    
    return 'Torre $tower, Piso $floor, Salón $roomNumber';
  }
}

