/// Constantes globales de la aplicación
class AppConstants {
  // API
  static const String apiTimeout = '30s';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Firebase Collections
  static const String usersCollection = 'usuarios';
  static const String studentsCollection = 'students';
  static const String bathroomsCollection = 'bathrooms';
  static const String mapasCollection = 'mapas';
  
  // Routes
  static const String loginRoute = '/auth/login';
  static const String homeRoute = '/home';
  static const String bathroomsRoute = '/bathrooms';
  static const String friendsRoute = '/friends';
  static const String navigationRoute = '/navigation';
  static const String chatbotRoute = '/chatbot';
}

