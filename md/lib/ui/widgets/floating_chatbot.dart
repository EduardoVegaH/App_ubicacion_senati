import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/chatbot_service.dart';

/// Widget de chatbot flotante con botón y chat desplegable
class FloatingChatbot extends StatefulWidget {
  final Map<String, dynamic>? studentData; // Información del estudiante
  
  const FloatingChatbot({super.key, this.studentData});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isChatOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Actualizar la información del estudiante en el servicio del chatbot
    if (widget.studentData != null) {
      _chatbotService.updateStudentData(widget.studentData);
    }
    // Mensaje de bienvenida personalizado
    final studentName = widget.studentData?['NameEstudent'] ?? '';
    final greeting = studentName.isNotEmpty 
        ? '¡Hola ${studentName.split(' ').first}! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte?'
        : '¡Hola! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte?';
    _messages.add(ChatMessage(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void didUpdateWidget(FloatingChatbot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la información del estudiante cambió, actualizar el servicio
    if (widget.studentData != oldWidget.studentData) {
      _chatbotService.updateStudentData(widget.studentData);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
      if (_isChatOpen) {
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Agregar mensaje del usuario
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Obtener respuesta del chatbot
    try {
      final response = await _chatbotService.sendMessage(message);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '❌ Error al obtener respuesta: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _chatbotService.resetChat();
      _messages.add(ChatMessage(
        text: '¡Hola! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final padding = mediaQuery.padding;
        final isTablet = screenSize.width > 600;
        final isLargePhone = screenSize.width >= 400 && !isTablet;
        
        // Calcular altura total de la pantalla
        final screenHeight = screenSize.height;
        
        // Cuando el teclado está abierto: usar todo el espacio disponible
        // Cuando no hay teclado: usar un porcentaje de la pantalla
        final chatHeight = keyboardHeight > 0
            ? screenHeight - keyboardHeight - padding.top - padding.bottom - 90 // Todo el espacio menos teclado y márgenes
            : (screenHeight * 0.65).clamp(400.0, 600.0); // 65% de la pantalla cuando no hay teclado
        
        // Ancho responsive: porcentaje del ancho de pantalla
        final chatWidth = isTablet 
            ? (screenSize.width * 0.38).clamp(350.0, 450.0)
            : isLargePhone 
                ? (screenSize.width * 0.90).clamp(320.0, 380.0)
                : (screenSize.width * 0.94).clamp(300.0, 360.0);
        
        // Posición bottom: ajustar dinámicamente
        final bottomPosition = keyboardHeight > 0 
            ? keyboardHeight + 8.0 // Justo encima del teclado
            : 80.0; // Posición normal

        return Stack(
          children: [
            // Chat flotante
            if (_isChatOpen)
              Positioned(
                bottom: bottomPosition,
                right: isTablet ? 20.0 : 16.0,
                left: isTablet ? null : 16.0,
                child: SizedBox(
                  width: chatWidth,
                  height: chatHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Header del chat
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B38E3).withOpacity(0.9),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.smart_toy,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Asistente Virtual',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'En línea',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                      onPressed: _clearChat,
                                      tooltip: 'Nueva conversación',
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
                                child: Container(
                                  color: Colors.transparent,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _messages.length) {
                                        return _buildLoadingIndicator();
                                      }
                                      return _buildMessageBubble(_messages[index], isLargePhone, isTablet);
                                    },
                                  ),
                                ),
                              ),

                              // Campo de entrada
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Escribe tu mensaje...',
                                          hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.8),
                                        ),
                                        style: const TextStyle(color: Colors.black),
                                        maxLines: null,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _sendMessage(),
                                        enabled: !_isLoading,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1B38E3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Icon(Icons.send, color: Colors.white),
                                        onPressed: _isLoading ? null : _sendMessage,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Botón flotante
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: _toggleChat,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B38E3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B38E3).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isChatOpen ? Icons.close : Icons.smart_toy,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLargePhone, bool isTablet) {
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
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
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

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B38E3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

