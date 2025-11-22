/// Utilidades para trabajar con IDs de salones y extraer información
class SalonHelper {
  /// Extrae el número de piso desde locationDetail o locationCode
  /// Ejemplos:
  /// - "Torre A, Piso 6, Salón 604" -> 2 (mapeado, ya que solo hay mapas para piso 1 y 2)
  /// - "IND - TORRE B 60TB - 200" -> 2 (del código 60TB, el B indica torre B, piso 2)
  /// 
  /// Nota: Mapea pisos altos (6, 7, etc.) al piso 2 del mapa interno
  static int extractPisoFromLocation(String locationDetail, String locationCode) {
    int pisoCurso = 1;
    
    // Intentar desde locationDetail primero
    final pisoMatch = RegExp(r'[Pp]iso\s+(\d+)').firstMatch(locationDetail);
    if (pisoMatch != null) {
      pisoCurso = int.parse(pisoMatch.group(1)!);
    } else {
      // Intentar desde locationCode (formato: IND - TORRE X 60TX - YYY)
      // En el código, el formato es 60TA, 60TB, 60TC donde la letra es la torre
      // No hay número de piso en el código, así que usamos el locationDetail
      // Si no hay piso en locationDetail, asumimos piso 1
    }
    
    // Mapear pisos del curso a pisos del mapa disponible
    // Los mapas disponibles son: piso 1 (exterior) y piso 2 (interior)
    // Si el curso dice piso 6, probablemente es el piso 2 del mapa interno
    if (pisoCurso >= 2) {
      // Pisos 2, 3, 4, 5, 6, etc. -> mapear al piso 2 (mapa interno)
      return 2;
    } else {
      // Piso 1 -> usar piso 1 (mapa exterior)
      return 1;
    }
  }

  /// Extrae el ID del salón desde locationDetail o locationCode
  /// Ejemplos:
  /// - "Torre A, Piso 6, Salón 604" -> "A-604" o "salon-A-604"
  /// - "IND - TORRE B 60TB - 200" -> "B-200" o "salon-B-200"
  static String extractSalonId(String locationDetail, String locationCode) {
    // Intentar desde locationDetail
    final salonMatch = RegExp(r'[Ss]al[oó]n\s+(\d+)').firstMatch(locationDetail);
    if (salonMatch != null) {
      final salonNumber = salonMatch.group(1)!;
      
      // Extraer torre
      final torreMatch = RegExp(r'[Tt]orre\s+([A-Z])').firstMatch(locationDetail);
      if (torreMatch != null) {
        final torre = torreMatch.group(1)!;
        return 'salon-$torre-$salonNumber';
      }
    }
    
    // Intentar desde locationCode (formato: IND - TORRE X 60TX - YYY)
    final codeMatch = RegExp(r'TORRE\s+([A-Z])\s+\d+[A-Z]+\s+-\s+(\d+)').firstMatch(locationCode);
    if (codeMatch != null) {
      final torre = codeMatch.group(1)!;
      final salonNumber = codeMatch.group(2)!;
      return 'salon-$torre-$salonNumber';
    }
    
    // Fallback: buscar cualquier número de 3 dígitos
    final numberMatch = RegExp(r'\d{3}').firstMatch(locationCode);
    if (numberMatch != null) {
      return 'salon-${numberMatch.group(0)}';
    }
    
    // Último recurso: usar el locationCode completo
    return locationCode;
  }

  /// Normaliza un ID de salón a formato estándar
  /// Ejemplos:
  /// - "A-604" -> "salon-A-604"
  /// - "salon-A-604" -> "salon-A-604"
  /// - "604" -> "salon-604"
  static String normalizeSalonId(String salonId) {
    if (salonId.startsWith('salon-')) {
      return salonId;
    }
    
    if (salonId.contains('-')) {
      return 'salon-$salonId';
    }
    
    return 'salon-$salonId';
  }
}

