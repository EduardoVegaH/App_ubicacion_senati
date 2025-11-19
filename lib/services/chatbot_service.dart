import 'package:google_generative_ai/google_generative_ai.dart';

/// Servicio para interactuar con el chatbot de IA usando Google Gemini
/// 
/// LLM utilizado: Google Gemini Pro (gratuito)
/// 
/// Para configurar la API key:
/// 1. Ve a: https://aistudio.google.com/app/apikey
/// 2. Inicia sesión con tu cuenta de Google
/// 3. Crea una nueva API key
/// 4. Reemplaza 'TU_API_KEY_AQUI' con tu API key real
class ChatbotService {
  // IMPORTANTE: Reemplaza esta API key con tu propia clave de Google Gemini
  // Obtén una gratis en: https://aistudio.google.com/app/apikey
  // O también en: https://makersuite.google.com/app/apikey
  static const String _apiKey = 'AIzaSyCTsng31Hx1QPPo5T2JTJ5OCle7ZLOnxtY';
  
  GenerativeModel? _model;
  ChatSession? _chat;

  ChatbotService() {
    // Inicializar el modelo Gemini solo si la API key está configurada
    if (_apiKey != 'TU_API_KEY_AQUI' && _apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Modelo gratuito y rápido de Gemini (actualizado)
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      
      // Inicializar la sesión de chat
      _chat = _model!.startChat();
    }
  }

  /// Envía un mensaje al chatbot y obtiene la respuesta
  Future<String> sendMessage(String message) async {
    // Verificar si la API key está configurada
    if (_apiKey == 'TU_API_KEY_AQUI' || _apiKey.isEmpty || _chat == null) {
      return '⚠️ Error: La API key no está configurada.\n\n'
             'Por favor:\n'
             '1. Ve a: https://aistudio.google.com/app/apikey\n'
             '2. Crea una API key gratuita\n'
             '3. Reemplaza "TU_API_KEY_AQUI" en lib/services/chatbot_service.dart\n'
             '4. Reinicia la aplicación';
    }
    
    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'Lo siento, no pude generar una respuesta.';
    } catch (e) {
      // Si hay error con la API key, retornar mensaje de error amigable
      if (e.toString().contains('API_KEY') || 
          e.toString().contains('401') || 
          e.toString().contains('API key not valid') ||
          e.toString().contains('invalid API key')) {
        return '⚠️ Error: La API key no es válida.\n\n'
               'Por favor:\n'
               '1. Ve a: https://aistudio.google.com/app/apikey\n'
               '2. Verifica que tu API key sea correcta\n'
               '3. Reemplaza "TU_API_KEY_AQUI" en lib/services/chatbot_service.dart\n'
               '4. Reinicia la aplicación';
      }
      return '❌ Error al procesar tu mensaje: ${e.toString()}';
    }
  }

  /// Reinicia la conversación
  void resetChat() {
    if (_apiKey != 'TU_API_KEY_AQUI' && _apiKey.isNotEmpty && _model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Verifica si la API key está configurada
  bool get isApiKeyConfigured => _apiKey != 'TU_API_KEY_AQUI';
}



