/// Utilidad para ocultar nodos azules del SVG antes de renderizarlo
/// 
/// Los nodos siguen existiendo en el SVG pero no son visibles
/// Esto permite que el sistema de navegación funcione sin mostrar los nodos al usuario
class SvgNodeHider {
  /// Oculta los nodos azules del SVG procesando el string
  /// 
  /// Busca círculos con id que empieza con "node" y fill="#0066FF"
  /// y los reemplaza para que no sean visibles
  static String hideNodesInSvg(String svgString) {
    // Patrón para encontrar círculos con id que empieza con "node" y fill="#0066FF"
    // Ejemplo: <circle id="node37" cx="1063" cy="697" r="10" fill="#0066FF"/>
    final nodePattern = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*fill=")#0066FF(")',
      multiLine: true,
    );
    
    // Reemplazar fill="#0066FF" por fill="none" para ocultar los nodos
    String modifiedSvg = svgString.replaceAllMapped(
      nodePattern,
      (match) => '${match.group(1)}none${match.group(2)}',
    );
    
    // También buscar y ocultar nodos que puedan tener el fill en diferentes posiciones
    // Patrón más flexible que busca cualquier círculo con id="node..." y fill="#0066FF"
    final nodePatternFlexible = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*?)(fill="#0066FF")([^>]*>)',
      multiLine: true,
    );
    
    modifiedSvg = modifiedSvg.replaceAllMapped(
      nodePatternFlexible,
      (match) {
        // Reemplazar fill="#0066FF" por fill="none" y agregar opacity="0"
        final before = match.group(1)!;
        final after = match.group(3)!;
        return '$before fill="none" opacity="0"$after';
      },
    );
    
    // También buscar paths que puedan ser nodos (como node_puerta_comedor)
    final pathNodePattern = RegExp(
      r'(<path\s+id="node[^"]*"[^>]*fill=")#0066FF(")',
      multiLine: true,
    );
    
    modifiedSvg = modifiedSvg.replaceAllMapped(
      pathNodePattern,
      (match) => '${match.group(1)}none${match.group(2)}',
    );
    
    return modifiedSvg;
  }
}

