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
  String? _currentModel;
  Map<String, dynamic>? _studentData; // Información del estudiante actual
  
  // Lista de modelos a probar en orden de preferencia
  // Según la documentación oficial de Google: gemini-2.5-flash es el más reciente
  static const List<String> _modelNames = [
    'gemini-2.5-flash',  // Modelo más reciente (2025)
    'gemini-1.5-flash',  // Modelo rápido y económico
    'gemini-1.5-pro',    // Modelo avanzado
    'gemini-pro',        // Modelo básico (fallback)
  ];

  ChatbotService() {
    // Inicializar el modelo Gemini solo si la API key está configurada
    if (_apiKey != 'TU_API_KEY_AQUI' && _apiKey.isNotEmpty) {
      _initializeModel();
    }
  }
  
  void _initializeModel() {
    // Intentar inicializar con el primer modelo de la lista
    if (_modelNames.isNotEmpty) {
      _currentModel = _modelNames[0];
      
      // Contexto del sistema: información sobre la app y cómo debe comportarse el chatbot
      // Nota: systemInstruction puede no estar disponible en todas las versiones
      // Si falla, el contexto se enviará en el primer mensaje
      
      _model = GenerativeModel(
        model: _currentModel!,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      
      // Inicializar la sesión de chat
      // El contexto se enviará como primer mensaje del sistema
      _chat = _model!.startChat();
      
      // Enviar el contexto del sistema como primer mensaje (asíncrono, no bloquea)
      _sendSystemContextOnce();
    }
  }
  
  
  /// Actualiza la información del estudiante y reinicializa el modelo con el nuevo contexto
  void updateStudentData(Map<String, dynamic>? studentData) {
    _studentData = studentData;
    // Reinicializar el modelo con el nuevo contexto que incluye la información del estudiante
    if (_apiKey != 'TU_API_KEY_AQUI' && _apiKey.isNotEmpty) {
      _initializeModel();
    }
  }
  
  /// Retorna el contexto del sistema para que el chatbot sepa en qué app está trabajando
  String _getSystemContext() {
    String baseContext = '''Eres un asistente virtual de SENATI (Servicio Nacional de Adiestramiento en Trabajo Industrial), una institución educativa técnica en Perú.

CONTEXTO DE LA APLICACIÓN:
- Esta es una aplicación móvil para estudiantes de SENATI
- La app ayuda a los estudiantes a navegar por el campus y acceder a información académica
- Los estudiantes pueden ver su información académica (semestre, asistencia, etc.)
- La app incluye un sistema de gestión de baños en tiempo real
- Hay mapas interactivos de las torres del campus (vista exterior e interior)
- Los estudiantes pueden ver el estado de los baños (operativo, en limpieza, inoperativo)
- La app permite navegación en tiempo real por el campus

TU ROL:
- Eres un asistente amigable y profesional
- Ayudas a los estudiantes con información sobre SENATI
- Puedes ayudar con preguntas sobre:
  * Información académica y carreras técnicas
  * Ubicaciones en el campus
  * Estado de servicios (baños, etc.)
  * Navegación por el campus
  * Procesos administrativos generales
  * Horarios y actividades
- Si no sabes algo específico, sé honesto y sugiere contactar con la administración
- Mantén un tono profesional pero cercano
- Responde siempre en español
- Sé conciso pero completo en tus respuestas
- NO repitas el saludo en cada respuesta, solo responde directamente a la pregunta
- Mantén la conversación fluida y natural, como si fuera una conversación continua

IMPORTANTE:
- No inventes información específica que no conozcas
- Si un estudiante pregunta sobre datos personales específicos (calificaciones, horarios exactos), sugiere que revise la app o contacte a su coordinador
- Enfócate en ser útil y orientador
- Responde de forma directa y concisa, sin repetir información que ya has dado''';

    // Si hay información del estudiante, agregarla al contexto
    if (_studentData != null) {
      final studentName = _studentData!['NameEstudent'] ?? '';
      final studentId = _studentData!['IdEstudiante'] ?? '';
      final semester = _studentData!['Semestre'] ?? '';
      final campus = _studentData!['Campus'] ?? '';
      final school = _studentData!['Escuela'] ?? '';
      final career = _studentData!['Carrera'] ?? '';
      final email = _studentData!['CorreoInstud'] ?? '';

      baseContext += '''

INFORMACIÓN DEL ESTUDIANTE ACTUAL:
- Nombre: $studentName
- ID de Estudiante: $studentId
- Semestre: $semester
- Campus: $campus
- Escuela: $school
- Carrera: $career
- Correo Institucional: $email

IMPORTANTE SOBRE LA INFORMACIÓN DEL ESTUDIANTE:
- Tienes acceso a la información del estudiante actual
- Cuando el estudiante pregunte por su ID, nombre, semestre, carrera, etc., puedes proporcionarle esta información directamente
- Usa esta información para dar respuestas personalizadas y útiles
- Si el estudiante pregunta "¿cuál es mi ID?" o "¿cuál es mi semestre?", puedes responder directamente con la información que tienes''';
    }

    return baseContext;
  }
  
  Future<bool> _tryNextModel() async {
    if (_currentModel == null) return false;
    
    final currentIndex = _modelNames.indexOf(_currentModel!);
    if (currentIndex < 0 || currentIndex >= _modelNames.length - 1) {
      return false; // No hay más modelos para probar
    }
    
    // Intentar con el siguiente modelo
    _currentModel = _modelNames[currentIndex + 1];
    
    // Mantener el mismo contexto del sistema
    
    _model = GenerativeModel(
      model: _currentModel!,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _chat = _model!.startChat();
    // Enviar el contexto del sistema
    _sendSystemContextOnce();
    return true;
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
      // Enviar solo el mensaje del usuario, el contexto ya está en el sistema
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'Lo siento, no pude generar una respuesta.';
    } catch (e) {
      final errorString = e.toString();
      
      // Si hay error con la API key, retornar mensaje de error amigable
      if (errorString.contains('API_KEY') || 
          errorString.contains('401') || 
          errorString.contains('API key not valid') ||
          errorString.contains('invalid API key')) {
        return '⚠️ Error: La API key no es válida.\n\n'
               'Por favor:\n'
               '1. Ve a: https://aistudio.google.com/app/apikey\n'
               '2. Verifica que tu API key sea correcta\n'
               '3. Reemplaza "TU_API_KEY_AQUI" en lib/services/chatbot_service.dart\n'
               '4. Reinicia la aplicación';
      }
      
      // Si hay error de cuota excedida
      if (errorString.contains('quota') || 
          errorString.contains('Quota exceeded') ||
          errorString.contains('rate limit') ||
          errorString.contains('rate-limit')) {
        return '⚠️ Límite de uso alcanzado\n\n'
               'Has alcanzado el límite gratuito de la API de Gemini.\n\n'
               'Opciones:\n'
               '1. Espera unos minutos y vuelve a intentar\n'
               '2. Revisa tu uso en: https://aistudio.google.com/app/apikey\n'
               '3. Considera actualizar tu plan si necesitas más solicitudes\n\n'
               'El límite gratuito es de 10 solicitudes por minuto.';
      }
      
      // Si el modelo no está disponible, intentar con el siguiente
      if (errorString.contains('not found') || 
          errorString.contains('not supported') ||
          errorString.contains('v1beta')) {
        final triedNext = await _tryNextModel();
        if (triedNext) {
          // Intentar de nuevo con el nuevo modelo
          try {
            final response = await _chat!.sendMessage(Content.text(message));
            return response.text ?? 'Lo siento, no pude generar una respuesta.';
          } catch (e2) {
            return '❌ Error: Ninguno de los modelos disponibles funciona.\n\n'
                   'Por favor verifica:\n'
                   '1. Que la API de Gemini esté habilitada en Google Cloud Console\n'
                   '2. Que tu API key tenga los permisos necesarios\n'
                   '3. Intenta crear una nueva API key en:\n'
                   '   https://aistudio.google.com/app/apikey\n\n'
                   'Error: ${e2.toString()}';
          }
        } else {
          return '❌ Error: El modelo "${_currentModel ?? 'desconocido'}" no está disponible.\n\n'
                 'Por favor:\n'
                 '1. Ve a Google Cloud Console\n'
                 '2. Habilita la API de "Generative Language API"\n'
                 '3. Verifica los permisos de tu API key\n'
                 '4. O crea una nueva API key en:\n'
                 '   https://aistudio.google.com/app/apikey\n\n'
                 'Error técnico: ${errorString}';
        }
      }
      
      return '❌ Error al procesar tu mensaje: ${errorString}';
    }
  }

  /// Envía el contexto del sistema una sola vez al inicio
  Future<void> _sendSystemContextOnce() async {
    if (_chat != null && _studentData != null) {
      try {
        // Enviar el contexto como un mensaje del sistema (solo una vez)
        final context = _getSystemContext();
        // Enviarlo de forma que el modelo lo entienda como contexto, no como mensaje del usuario
        await _chat!.sendMessage(Content.text('SISTEMA: $context'));
      } catch (e) {
        // Si falla, no es crítico
      }
    }
  }
  
  /// Reinicia la conversación (mantiene la información del estudiante)
  void resetChat() {
    if (_apiKey != 'TU_API_KEY_AQUI' && _apiKey.isNotEmpty && _model != null) {
      _chat = _model!.startChat();
      // Enviar el contexto de nuevo después de reiniciar
      _sendSystemContextOnce();
    }
  }

  /// Verifica si la API key está configurada
  bool get isApiKeyConfigured => _apiKey != 'TU_API_KEY_AQUI';
}



