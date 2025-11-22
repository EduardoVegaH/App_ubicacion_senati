import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un nodo en el mapa (salón, área, punto de interés)
class NodoMapa {
  /// Identificador único del nodo (ej: "salon-201", "entrada-principal")
  final String id;
  
  /// Coordenada X en el sistema de coordenadas del mapa
  final double x;
  
  /// Coordenada Y en el sistema de coordenadas del mapa
  final double y;
  
  /// Lista de IDs de nodos conectados (ej: ["salon-202", "pasillo-1"])
  final List<String> conexiones;

  const NodoMapa({
    required this.id,
    required this.x,
    required this.y,
    this.conexiones = const [],
  });

  /// Crea un NodoMapa desde un Map (útil para deserialización JSON)
  factory NodoMapa.fromJson(Map<String, dynamic> json) {
    return NodoMapa(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      conexiones: json['conexiones'] != null
          ? List<String>.from(json['conexiones'] as List)
          : [],
    );
  }

  /// Convierte el NodoMapa a un Map (útil para serialización JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'conexiones': conexiones,
    };
  }

  /// Carga una lista de nodos desde un archivo JSON en assets
  /// 
  /// El archivo JSON debe tener el siguiente formato:
  /// ```json
  /// {
  ///   "nodos": [
  ///     {
  ///       "id": "salon-201",
  ///       "x": 100.5,
  ///       "y": 200.3,
  ///       "conexiones": ["salon-202", "pasillo-1"]
  ///     },
  ///     {
  ///       "id": "salon-202",
  ///       "x": 150.0,
  ///       "y": 200.3,
  ///       "conexiones": ["salon-201", "salon-203"]
  ///     }
  ///   ]
  /// }
  /// ```
  /// 
  /// O alternativamente, un array directo:
  /// ```json
  /// [
  ///   {
  ///     "id": "salon-201",
  ///     "x": 100.5,
  ///     "y": 200.3,
  ///     "conexiones": ["salon-202"]
  ///   }
  /// ]
  /// ```
  static Future<List<NodoMapa>> cargarDesdeAssets(String assetPath) async {
    try {
      // Cargar el archivo JSON desde assets
      final String jsonString = await rootBundle.loadString(assetPath);
      
      // Parsear el JSON
      final dynamic jsonData = json.decode(jsonString);
      
      List<dynamic> nodosJson;
      
      // Verificar si el JSON tiene un objeto con clave "nodos" o es un array directo
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('nodos')) {
        nodosJson = jsonData['nodos'] as List<dynamic>;
      } else if (jsonData is List<dynamic>) {
        nodosJson = jsonData;
      } else {
        throw FormatException(
          'El archivo JSON debe contener un objeto con clave "nodos" o un array directo de nodos',
        );
      }
      
      // Convertir cada elemento JSON a un NodoMapa
      return nodosJson
          .map((json) => NodoMapa.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar nodos desde $assetPath: $e');
    }
  }

  /// Carga nodos desde un String JSON (útil para testing o datos en memoria)
  static List<NodoMapa> cargarDesdeJsonString(String jsonString) {
    try {
      final dynamic jsonData = json.decode(jsonString);
      
      List<dynamic> nodosJson;
      
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('nodos')) {
        nodosJson = jsonData['nodos'] as List<dynamic>;
      } else if (jsonData is List<dynamic>) {
        nodosJson = jsonData;
      } else {
        throw FormatException(
          'El JSON debe contener un objeto con clave "nodos" o un array directo de nodos',
        );
      }
      
      return nodosJson
          .map((json) => NodoMapa.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al parsear JSON: $e');
    }
  }

  /// Crea un NodoMapa desde un documento de Firestore
  factory NodoMapa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NodoMapa(
      id: doc.id,
      x: (data['x'] as num?)?.toDouble() ?? 0.0,
      y: (data['y'] as num?)?.toDouble() ?? 0.0,
      conexiones: data['conexiones'] != null
          ? List<String>.from(data['conexiones'] as List)
          : [],
    );
  }

  /// Carga nodos desde la colección 'salones' de Firestore
  static Future<List<NodoMapa>> cargarDesdeFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('salones').get();
      
      return snapshot.docs
          .map((doc) => NodoMapa.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar nodos desde Firestore: $e');
    }
  }

  /// Escucha cambios en tiempo real de la colección 'salones' de Firestore
  static Stream<List<NodoMapa>> escucharDesdeFirestore() {
    try {
      final firestore = FirebaseFirestore.instance;
      return firestore
          .collection('salones')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NodoMapa.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Error al escuchar nodos desde Firestore: $e');
    }
  }

  /// Encuentra un nodo por su ID en una lista de nodos
  static NodoMapa? buscarPorId(List<NodoMapa> nodos, String id) {
    try {
      return nodos.firstWhere((nodo) => nodo.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Calcula la distancia entre dos nodos
  double distanciaA(NodoMapa otro) {
    final dx = x - otro.x;
    final dy = y - otro.y;
    return (dx * dx + dy * dy);
  }

  /// Calcula la distancia euclidiana entre dos nodos
  double distanciaEuclidianaA(NodoMapa otro) {
    final dx = x - otro.x;
    final dy = y - otro.y;
    return (dx * dx + dy * dy);
  }

  @override
  String toString() {
    return 'NodoMapa(id: $id, x: $x, y: $y, conexiones: ${conexiones.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NodoMapa && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

