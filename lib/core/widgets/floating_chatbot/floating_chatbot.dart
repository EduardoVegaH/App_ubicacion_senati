import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/styles/app_styles.dart';
import '../../../app/styles/app_shadows.dart';
import '../../../core/di/injection_container.dart';
import '../../../features/chatbot/domain/index.dart';
import '../../../features/chatbot/presentation/widgets/index.dart';
import '../../../features/chatbot/domain/entities/chat_message_entity.dart';

/// Widget de chatbot flotante con botón y chat desplegable
class FloatingChatbot extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  
  const FloatingChatbot({super.key, this.studentData});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot> {
  late final ChatbotRepository _repository;
  late final SendMessageUseCase _sendMessageUseCase;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageEntity> _messages = [];
  bool _isChatOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = sl<ChatbotRepository>();
    _sendMessageUseCase = sl<SendMessageUseCase>();
    
    if (widget.studentData != null) {
      _repository.updateStudentData(widget.studentData);
    }
    
    final studentName = widget.studentData?['NameEstudent'] ?? '';
    final greeting = studentName.isNotEmpty 
        ? '¡Hola ${studentName.split(' ').first}! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte?'
        : '¡Hola! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte?';
    _messages.add(ChatMessageEntity(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void didUpdateWidget(FloatingChatbot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studentData != oldWidget.studentData) {
      _repository.updateStudentData(widget.studentData);
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

    setState(() {
      _messages.add(ChatMessageEntity(text: message, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _sendMessageUseCase.call(message);
      
      setState(() {
        _messages.add(ChatMessageEntity(text: response, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessageEntity(text: '❌ Error al obtener respuesta: $e', isUser: false, timestamp: DateTime.now()));
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
      _repository.resetChat();
      _messages.add(ChatMessageEntity(
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
        
        // Calcular posición bottom: cuando hay teclado, colocar justo encima del teclado
        // Cuando no hay teclado, usar posición fija
        final bottomPosition = keyboardHeight > 0 
            ? keyboardHeight + 8.0
            : 20.0;
        
        // Calcular altura máxima posible (nunca debe tocar el notch/status bar)
        // padding.top incluye status bar + notch, agregamos margen adicional para seguridad
        final maxPossibleHeight = screenSize.height 
            - padding.top    // evitar notch/status bar
            - 120.0;         // margen adicional para no tapar la barra de estado
        
        // Calcular altura deseada del chat
        // Con teclado: 45% de la pantalla (más compacto)
        // Sin teclado: 55% de la pantalla (flotante abajo, sin tapar status bar)
        final desiredHeight = screenSize.height * (keyboardHeight > 0 ? 0.45 : 0.55);
        
        // Usar la menor entre la altura deseada y la máxima posible
        // Mínimo 250px para usabilidad, máximo según límites de pantalla
        final finalChatHeight = desiredHeight.clamp(250.0, maxPossibleHeight);
        
        final chatWidth = isTablet 
            ? (screenSize.width * 0.38).clamp(350.0, 450.0)
            : isLargePhone 
                ? (screenSize.width * 0.90).clamp(320.0, 380.0)
                : (screenSize.width * 0.94).clamp(300.0, 360.0);

        return Stack(
          children: [
            if (_isChatOpen)
              Positioned(
                left: isTablet ? null : 16.0,
                right: isTablet ? 20.0 : 16.0,
                bottom: bottomPosition,
                child: SizedBox(
                  width: chatWidth,
                  height: finalChatHeight,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppStyles.whiteOverlayLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppStyles.whiteOverlayLight, width: 1),
                          ),
                          child: Column(
                            children: [
                              ChatHeader(
                                title: 'Asistente Virtual',
                                subtitle: 'En línea',
                                onRefresh: _clearChat,
                                onClose: _toggleChat,
                              ),
                              Flexible(
                                child: Container(
                                  color: Colors.transparent,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _messages.length) {
                                        return const ChatLoadingIndicator();
                                      }
                                      return ChatMessageBubble(
                                        message: _messages[index],
                                        isLargePhone: isLargePhone,
                                        isTablet: isTablet,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              ChatInputField(
                                controller: _messageController,
                                onSend: _sendMessage,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Botón flotante solo visible cuando el chat está cerrado
            if (!_isChatOpen)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleChat,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.floatingButtonShadow(AppStyles.primaryColor),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

}

