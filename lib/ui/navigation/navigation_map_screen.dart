import 'package:flutter/material.dart';
import '../widgets/mapa_interactivo.dart';
import '../widgets/ruta_painter.dart';
import '../../models/nodo_mapa.dart';
import '../../services/calculador_rutas.dart';
import '../../services/chatbot_service.dart';

/// Pantalla de navegación a pantalla completa
/// Muestra el mapa interactivo con detección de salones y cálculo de rutas
class NavigationMapScreen extends StatefulWidget {
  final String? locationName;
  final String? locationDetail;
  final String? initialView; // 'exterior' o 'interior'

  const NavigationMapScreen({
    super.key,
    this.locationName,
    this.locationDetail,
    this.initialView,
  });

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  // Punto inicial fijo (simulado)
  static const double _puntoInicialX = 50.0;
  static const double _puntoInicialY = 50.0;
  static const String _puntoInicialId = 'punto-inicial';

  List<NodoMapa> _nodos = [];
  String? _salonSeleccionado;
  List<NodoMapa> _ruta = [];
  bool _cargandoNodos = true;
  
  // Chatbot
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];
  bool _isChatLoading = false;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    _cargarNodos();
    _inicializarChatbot();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  /// Inicializa el chatbot con contexto de navegación
  void _inicializarChatbot() {
    // Actualizar el contexto del chatbot con información de navegación
    final salonesDisponibles = _obtenerSalonesDisponibles()
        .map((n) => n.id)
        .join(', ');
    
    _chatbotService.updateStudentData({
      'contexto': 'navegacion',
      'salones_disponibles': salonesDisponibles,
      'punto_inicial': _puntoInicialId,
    });
    
    // Mensaje de bienvenida
    _chatMessages.add(ChatMessage(
      text: '¡Hola! Soy tu asistente de navegación. Puedo ayudarte a encontrar salones y calcular rutas.\n\n'
            'Puedes escribir:\n'
            '• "llévame al salón 201"\n'
            '• "¿dónde está el salón 202?"\n'
            '• "ruta al salón 203"\n\n'
            'También puedes seleccionar un destino desde el menú superior.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Carga los nodos del mapa desde Firestore o assets
  Future<void> _cargarNodos() async {
    try {
      setState(() {
        _cargandoNodos = true;
      });

      // Intentar cargar nodos desde Firestore primero
      try {
        _nodos = await NodoMapa.cargarDesdeFirestore();
        if (_nodos.isEmpty) {
          // Si Firestore está vacío, intentar desde assets
          try {
            _nodos = await NodoMapa.cargarDesdeAssets('assets/nodos_mapa.json');
          } catch (e) {
            // Si no existe el archivo, crear nodos de ejemplo
            _nodos = _crearNodosEjemplo();
          }
        }
      } catch (e) {
        print('⚠️ Error al cargar desde Firestore: $e');
        // Si hay error con Firestore, intentar desde assets
        try {
          _nodos = await NodoMapa.cargarDesdeAssets('assets/nodos_mapa.json');
        } catch (e2) {
          // Si no existe el archivo, crear nodos de ejemplo
          _nodos = _crearNodosEjemplo();
        }
      }

      // Agregar el punto inicial a la lista de nodos si no existe
      if (NodoMapa.buscarPorId(_nodos, _puntoInicialId) == null) {
        _nodos.add(NodoMapa(
          id: _puntoInicialId,
          x: _puntoInicialX,
          y: _puntoInicialY,
          conexiones: _nodos.isNotEmpty ? [_nodos.first.id] : [],
        ));
      }

      // Validar que el salón seleccionado existe en los nuevos nodos
      if (_salonSeleccionado != null) {
        final existe = _obtenerSalonesDisponibles()
            .any((nodo) => nodo.id == _salonSeleccionado);
        if (!existe) {
          _salonSeleccionado = null;
          _ruta = [];
        }
      }

      setState(() {
        _cargandoNodos = false;
      });
      
      // Reinicializar el chatbot con los nuevos nodos
      if (mounted) {
        _inicializarChatbot();
      }
    } catch (e) {
      setState(() {
        _cargandoNodos = false;
        _nodos = _crearNodosEjemplo();
      });
    }
  }

  /// Crea nodos de ejemplo si no existe el archivo JSON
  List<NodoMapa> _crearNodosEjemplo() {
    return [
      NodoMapa(
        id: _puntoInicialId,
        x: _puntoInicialX,
        y: _puntoInicialY,
        conexiones: ['salon-201', 'pasillo-1'],
      ),
      NodoMapa(
        id: 'salon-201',
        x: 150.0,
        y: 200.0,
        conexiones: [_puntoInicialId, 'salon-202', 'pasillo-1'],
      ),
      NodoMapa(
        id: 'salon-202',
        x: 250.0,
        y: 200.0,
        conexiones: ['salon-201', 'salon-203', 'pasillo-1'],
      ),
      NodoMapa(
        id: 'salon-203',
        x: 350.0,
        y: 200.0,
        conexiones: ['salon-202', 'pasillo-1'],
      ),
      NodoMapa(
        id: 'pasillo-1',
        x: 200.0,
        y: 150.0,
        conexiones: [_puntoInicialId, 'salon-201', 'salon-202', 'salon-203'],
      ),
    ];
  }

  /// Calcula la ruta desde el punto inicial hasta un destino
  void _calcularRuta(String idDestino) {
    setState(() {
      _salonSeleccionado = idDestino;
    });

    // Buscar el nodo destino
    final nodoDestino = NodoMapa.buscarPorId(_nodos, idDestino);
    
    if (nodoDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destino no encontrado'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calcular la ruta desde el punto inicial hasta el destino
    try {
      final ruta = CalculadorRutas.calcularRuta(
        _puntoInicialId,
        idDestino,
        _nodos,
      );

      setState(() {
        _ruta = ruta;
      });

      // Mostrar información de la ruta
      if (ruta.isNotEmpty) {
        final distancia = CalculadorRutas.calcularDistanciaRuta(ruta);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta encontrada: ${ruta.length} pasos (${distancia.toStringAsFixed(1)} unidades)',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1B38E3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró ruta al destino'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular ruta: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Maneja cuando se toca un elemento del mapa
  void _onElementoTocado(String? elementoId) {
    if (elementoId == null) return;
    _calcularRuta(elementoId);
  }

  /// Obtiene la lista de salones disponibles (excluyendo el punto inicial)
  /// Elimina duplicados por ID para evitar errores en el DropdownButton
  List<NodoMapa> _obtenerSalonesDisponibles() {
    final salones = _nodos.where((nodo) => nodo.id != _puntoInicialId).toList();
    // Eliminar duplicados por ID (mantener solo el primero)
    final idsVistos = <String>{};
    return salones.where((nodo) {
      if (idsVistos.contains(nodo.id)) {
        return false; // Duplicado, ignorar
      }
      idsVistos.add(nodo.id);
      return true;
    }).toList();
  }

  /// Extrae el número de salón de un mensaje (ej: "llévame al salón 101" -> "salon-101")
  String? _extraerSalonDelMensaje(String mensaje) {
    final mensajeLower = mensaje.toLowerCase();
    
    // Buscar patrones como "salón 101", "salon 201", "101", etc.
    final patrones = [
      RegExp(r'sal[oó]n\s+(\d+)', caseSensitive: false),
      RegExp(r'salon\s+(\d+)', caseSensitive: false),
      RegExp(r'a[l]?\s+sal[oó]n\s+(\d+)', caseSensitive: false),
      RegExp(r'(\d{3,})', caseSensitive: false), // Números de 3 o más dígitos
    ];

    for (final patron in patrones) {
      final match = patron.firstMatch(mensajeLower);
      if (match != null) {
        final numero = match.group(1);
        if (numero == null) continue;
        
        // Intentar diferentes formatos de ID
        final posiblesIds = [
          'salon-$numero',
          'salon-${numero.padLeft(3, '0')}', // Formato con ceros a la izquierda
          numero,
          'salon-$numero',
        ];
        
        // Buscar el ID que existe en los nodos
        for (final id in posiblesIds) {
          final nodo = NodoMapa.buscarPorId(_nodos, id);
          if (nodo != null) {
            return id;
          }
        }
        
        // Si no se encuentra exacto, buscar por coincidencia parcial
        final nodosCoincidentes = _nodos.where((nodo) {
          return nodo.id.toLowerCase().contains(numero) ||
                 nodo.id.toLowerCase().contains('salon-$numero');
        }).toList();
        
        if (nodosCoincidentes.isNotEmpty) {
          return nodosCoincidentes.first.id;
        }
      }
    }
    return null;
  }

  /// Procesa un mensaje del chatbot y detecta comandos de navegación
  Future<void> _procesarMensajeChat(String mensaje) async {
    if (mensaje.trim().isEmpty || _isChatLoading) return;

    // Agregar mensaje del usuario
    setState(() {
      _chatMessages.add(ChatMessage(
        text: mensaje,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isChatLoading = true;
    });

    _chatController.clear();
    _scrollChatAlFinal();

    // Detectar si el mensaje contiene un comando de navegación
    final salonId = _extraerSalonDelMensaje(mensaje.toLowerCase());
    
    if (salonId != null) {
      // Calcular ruta automáticamente
      _calcularRuta(salonId);
      
      final nodo = NodoMapa.buscarPorId(_nodos, salonId);
      if (nodo != null && _ruta.isNotEmpty) {
        final distancia = CalculadorRutas.calcularDistanciaRuta(_ruta);
        setState(() {
          _chatMessages.add(ChatMessage(
            text: '✅ Ruta calculada al ${nodo.id}:\n\n'
                  '📍 Pasos: ${_ruta.length}\n'
                  '📏 Distancia: ${distancia.toStringAsFixed(1)} unidades\n\n'
                  'La ruta se ha dibujado en el mapa.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isChatLoading = false;
        });
      } else {
        setState(() {
          _chatMessages.add(ChatMessage(
            text: '❌ No se pudo encontrar una ruta al ${salonId}. Verifica que el salón existe y está conectado.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isChatLoading = false;
        });
      }
    } else {
      // Enviar mensaje al chatbot de IA
      try {
        // Agregar contexto sobre los salones disponibles
        final salonesDisponibles = _obtenerSalonesDisponibles()
            .map((n) => n.id)
            .join(', ');
        
        final mensajeConContexto = 'Contexto: Estoy en una app de navegación de SENATI. '
            'Salones disponibles: $salonesDisponibles. '
            'Puedo calcular rutas desde el punto inicial (50, 50) a cualquier salón. '
            'Si el usuario pide ir a un salón, puedo calcular la ruta. '
            'Mensaje del usuario: $mensaje';
        
        final respuesta = await _chatbotService.sendMessage(mensajeConContexto);
        
        setState(() {
          _chatMessages.add(ChatMessage(
            text: respuesta,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isChatLoading = false;
        });
      } catch (e) {
        setState(() {
          _chatMessages.add(ChatMessage(
            text: '❌ Error al procesar tu mensaje: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isChatLoading = false;
        });
      }
    }

    _scrollChatAlFinal();
  }

  void _scrollChatAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
      if (_isChatOpen) {
        _scrollChatAlFinal();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    // Determinar qué SVG usar según la vista inicial
    final svgPath = widget.initialView == 'exterior'
        ? 'assets/Torres_ext.svg'
        : 'assets/Torres_int.svg';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con información, dropdown y botón de cerrar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                vertical: isLargePhone ? 12 : (isTablet ? 14 : 10),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1B38E3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Botón de cerrar
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      // Información de ubicación
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.locationDetail != null)
                              Text(
                                widget.locationDetail!,
                                style: TextStyle(
                                  fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (widget.locationName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.locationName!,
                                style: TextStyle(
                                  fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Icono de navegación
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  // Dropdown para seleccionar destino
                  if (!_cargandoNodos && _obtenerSalonesDisponibles().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final salonesDisponibles = _obtenerSalonesDisponibles();
                                // Validar que el valor seleccionado existe en los items
                                String? valorValido = _salonSeleccionado;
                                if (valorValido != null) {
                                  final existe = salonesDisponibles.any((nodo) => nodo.id == valorValido);
                                  if (!existe) {
                                    valorValido = null;
                                  }
                                }
                                
                                return DropdownButton<String>(
                                  value: valorValido,
                                  hint: Text(
                                    'Selecciona un destino',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                                    ),
                                  ),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                  dropdownColor: const Color(0xFF1B38E3),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                                  ),
                                  items: salonesDisponibles.map((nodo) {
                                    return DropdownMenuItem<String>(
                                      value: nodo.id,
                                      child: Text(
                                        nodo.id,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? nuevoDestino) {
                                    if (nuevoDestino != null) {
                                      setState(() {
                                        _salonSeleccionado = nuevoDestino;
                                      });
                                      _calcularRuta(nuevoDestino);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Mapa a pantalla completa con ruta superpuesta
            Expanded(
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    // Mapa interactivo
                    MapaInteractivo(
                      svgAssetPath: svgPath,
                      height: null, // Usará todo el espacio disponible
                      showControls: true,
                      onElementTapped: _onElementoTocado,
                    ),

                    // Dibujar la ruta sobre el mapa
                    if (_ruta.isNotEmpty)
                      CustomPaint(
                        painter: RutaPainter(
                          puntos: _ruta.map((nodo) => Offset(nodo.x, nodo.y)).toList(),
                          color: const Color(0xFF1B38E3),
                          strokeWidth: 4.0,
                          mostrarPuntos: true,
                          puntoRadio: 6.0,
                          mostrarFlechas: true,
                          flechaColor: const Color(0xFF1B38E3),
                        ),
                      ),

                    // Indicador de punto inicial
                    Positioned(
                      left: _puntoInicialX - 8,
                      top: _puntoInicialY - 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chatbot integrado (se expande desde abajo)
            if (_isChatOpen)
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header del chat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B38E3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Asistente de Navegación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: _toggleChat,
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de mensajes
                    Expanded(
                      child: ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _chatMessages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return _buildChatBubble(_chatMessages[index], isLargePhone, isTablet);
                        },
                      ),
                    ),
                    
                    // Campo de entrada
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1B38E3),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _procesarMensajeChat(_chatController.text),
                              enabled: !_isChatLoading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B38E3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: _isChatLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                              onPressed: _isChatLoading
                                  ? null
                                  : () => _procesarMensajeChat(_chatController.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Barra inferior con botón de chat o información
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                vertical: isLargePhone ? 12 : (isTablet ? 14 : 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (!_isChatOpen) ...[
                    Icon(
                      Icons.info_outline,
                      size: isLargePhone ? 18 : (isTablet ? 20 : 16),
                      color: const Color(0xFF757575),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cargandoNodos
                            ? 'Cargando mapa...'
                            : _ruta.isNotEmpty
                                ? 'Ruta calculada: ${_ruta.length} pasos'
                                : 'Toca un salón o usa el chat para navegar',
                        style: TextStyle(
                          fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                    if (_ruta.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: const Color(0xFF757575),
                        onPressed: () {
                          setState(() {
                            _ruta = [];
                            _salonSeleccionado = null;
                          });
                        },
                        tooltip: 'Limpiar ruta',
                      ),
                  ] else ...[
                    // Cuando el chat está abierto, solo mostrar botón para cerrar
                    Expanded(
                      child: Text(
                        'Escribe "llévame al salón X" para calcular una ruta',
                        style: TextStyle(
                          fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                  // Botón para abrir/cerrar chat
                  IconButton(
                    icon: Icon(
                      _isChatOpen ? Icons.keyboard_arrow_down : Icons.chat_bubble_outline,
                      color: const Color(0xFF1B38E3),
                      size: 24,
                    ),
                    onPressed: _toggleChat,
                    tooltip: _isChatOpen ? 'Cerrar chat' : 'Abrir chat',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una burbuja de chat estilo WhatsApp
  Widget _buildChatBubble(ChatMessage message, bool isLargePhone, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1B38E3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF1B38E3)
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1B38E3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Color(0xFF1B38E3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modelo para mensajes del chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

