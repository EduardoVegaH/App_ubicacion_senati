import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_shadows.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../data/index.dart';
import '../../domain/index.dart';
import '../../data/models/chat_message.dart';
import '../widgets/index.dart';

/// Página de chatbot (refactorizada)
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final ChatbotRemoteDataSource _dataSource;
  late final ChatbotRepositoryImpl _repository;
  late final SendMessageUseCase _sendMessageUseCase;
  late final ResetChatUseCase _resetChatUseCase;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataSource = ChatbotRemoteDataSource();
    _repository = ChatbotRepositoryImpl(_dataSource);
    _sendMessageUseCase = SendMessageUseCase(_repository);
    _resetChatUseCase = ResetChatUseCase(_repository);
    
    _messages.add(ChatMessage(
      text: '¡Hola! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte hoy?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _sendMessageUseCase.call(message);
      
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: '❌ Error al obtener respuesta: $e', isUser: false, timestamp: DateTime.now()));
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
    _resetChatUseCase.call();
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: '¡Hola! Soy tu asistente virtual de SENATI. ¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('Asistente Virtual'),
          ],
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nueva conversación',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
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
          Container(
            decoration: BoxDecoration(
              color: AppStyles.surfaceColor,
              boxShadow: AppShadows.popupShadow,
            ),
            child: SafeArea(
              child: Padding(
                padding: AppSpacing.elementPaddingTiny(isLargePhone, isTablet),
                child: ChatInputField(
                  controller: _messageController,
                  onSend: _sendMessage,
                  isLoading: _isLoading,
                  showContainerStyle: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

