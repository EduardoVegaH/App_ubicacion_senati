# Configuración del Chatbot de IA

## 📋 Pasos para configurar el chatbot

### 1. Obtener API Key de Google Gemini (GRATIS)

1. Ve a: https://makersuite.google.com/app/apikey
2. Inicia sesión con tu cuenta de Google
3. Haz clic en "Create API Key" o "Get API Key"
4. Copia la API key que se genera

### 2. Configurar la API Key en el código

1. Abre el archivo: `lib/services/chatbot_service.dart`
2. Busca la línea que dice:
   ```dart
   static const String _apiKey = 'TU_API_KEY_AQUI';
   ```
3. Reemplaza `'TU_API_KEY_AQUI'` con tu API key:
   ```dart
   static const String _apiKey = 'TU_API_KEY_REAL_AQUI';
   ```

### 3. ¡Listo!

El chatbot ya está integrado en la app. Los usuarios pueden acceder a él desde:
- **Menú lateral (Drawer)** → **Asistente Virtual**

## 💰 Costos

- **Google Gemini Pro**: Gratis hasta 60 solicitudes por minuto
- **Límite diario**: 1,500 solicitudes (más que suficiente para uso normal)
- **Sin tarjeta de crédito requerida** para el tier gratuito

## 🎯 Características del Chatbot

- ✅ Interfaz de chat moderna y responsive
- ✅ Respuestas en tiempo real
- ✅ Historial de conversación
- ✅ Botón para nueva conversación
- ✅ Indicadores de carga
- ✅ Diseño adaptado a diferentes tamaños de pantalla

## ⚠️ Nota Importante

**NUNCA** subas tu API key a repositorios públicos. Si vas a hacer commit del código, asegúrate de:
1. Usar variables de entorno, o
2. Agregar `lib/services/chatbot_service.dart` al `.gitignore`

## 🔧 Solución de Problemas

Si el chatbot muestra un error sobre la API key:
1. Verifica que la API key esté correctamente copiada (sin espacios extra)
2. Asegúrate de que la API key esté entre comillas simples: `'TU_API_KEY'`
3. Verifica que tengas conexión a internet
4. Revisa que la API key no haya expirado o sido revocada



