import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para inicializar salones en Firebase Firestore
/// Crea la colección 'salones' con información de salones, sus coordenadas y conexiones
class SalonesInitializer {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  /// Inicializa los salones en Firebase
  /// Crea la colección 'salones' con todos los salones del campus SENATI
  Future<void> initializeSalones() async {
    try {
      final snapshot = await _db.collection('salones').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return;
      }

      // Obtener lista de salones
      final salones = _getSalonesData();

      // Crear cada salón en Firestore
      int creados = 0;
      for (final salon in salones) {
        try {
          // Usar el ID del salón como ID del documento
          await _db.collection('salones').doc(salon['id'] as String).set({
            ...salon,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          creados++;
        } catch (e) {
          print('Error al crear salón ${salon['id']}: $e');
        }
      }
    } catch (e) {
      print('Error al inicializar salones: $e');
      rethrow;
    }
  }

  /// Limpia todos los salones de la colección
  Future<void> clearSalones() async {
    try {
      final snapshot = await _db.collection('salones').get();
      final batch = _db.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error al limpiar salones: $e');
      rethrow;
    }
  }

  /// Obtiene los datos de los salones
  /// Incluye salones de diferentes pisos y torres
  List<Map<String, dynamic>> _getSalonesData() {
    return [
      // ========== TORRE A ==========
      // Piso 1 - Torre A
      {
        'id': 'salon-A-101',
        'nombre': 'Salón A-101',
        'piso': 1,
        'torre': 'A',
        'x': 100.0,
        'y': 300.0,
        'conexiones': ['pasillo-A-1', 'salon-A-102'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-A-102',
        'nombre': 'Salón A-102',
        'piso': 1,
        'torre': 'A',
        'x': 200.0,
        'y': 300.0,
        'conexiones': ['salon-A-101', 'salon-A-103', 'pasillo-A-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-A-103',
        'nombre': 'Salón A-103',
        'piso': 1,
        'torre': 'A',
        'x': 300.0,
        'y': 300.0,
        'conexiones': ['salon-A-102', 'pasillo-A-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-A-1',
        'nombre': 'Pasillo Principal Torre A - Piso 1',
        'piso': 1,
        'torre': 'A',
        'x': 200.0,
        'y': 250.0,
        'conexiones': ['salon-A-101', 'salon-A-102', 'salon-A-103', 'escaleras-A-1-2'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'escaleras-A-1-2',
        'nombre': 'Escaleras Torre A (Piso 1-2)',
        'piso': 1,
        'torre': 'A',
        'x': 150.0,
        'y': 200.0,
        'conexiones': ['pasillo-A-1', 'pasillo-A-2'],
        'tipo': 'escaleras',
        'capacidad': null,
        'descripcion': 'Escaleras entre pisos',
      },

      // Piso 2 - Torre A
      {
        'id': 'salon-A-201',
        'nombre': 'Salón A-201',
        'piso': 2,
        'torre': 'A',
        'x': 100.0,
        'y': 500.0,
        'conexiones': ['pasillo-A-2', 'salon-A-202'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-A-202',
        'nombre': 'Salón A-202',
        'piso': 2,
        'torre': 'A',
        'x': 200.0,
        'y': 500.0,
        'conexiones': ['salon-A-201', 'salon-A-203', 'pasillo-A-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-A-203',
        'nombre': 'Salón A-203',
        'piso': 2,
        'torre': 'A',
        'x': 300.0,
        'y': 500.0,
        'conexiones': ['salon-A-202', 'pasillo-A-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-A-2',
        'nombre': 'Pasillo Principal Torre A - Piso 2',
        'piso': 2,
        'torre': 'A',
        'x': 200.0,
        'y': 450.0,
        'conexiones': ['salon-A-201', 'salon-A-202', 'salon-A-203', 'escaleras-A-1-2', 'escaleras-A-2-3'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'escaleras-A-2-3',
        'nombre': 'Escaleras Torre A (Piso 2-3)',
        'piso': 2,
        'torre': 'A',
        'x': 150.0,
        'y': 400.0,
        'conexiones': ['pasillo-A-2', 'pasillo-A-3'],
        'tipo': 'escaleras',
        'capacidad': null,
        'descripcion': 'Escaleras entre pisos',
      },

      // Piso 3 - Torre A
      {
        'id': 'salon-A-301',
        'nombre': 'Salón A-301',
        'piso': 3,
        'torre': 'A',
        'x': 100.0,
        'y': 700.0,
        'conexiones': ['pasillo-A-3', 'salon-A-302'],
        'tipo': 'laboratorio',
        'capacidad': 25,
        'descripcion': 'Laboratorio de informática',
      },
      {
        'id': 'salon-A-302',
        'nombre': 'Salón A-302',
        'piso': 3,
        'torre': 'A',
        'x': 200.0,
        'y': 700.0,
        'conexiones': ['salon-A-301', 'salon-A-303', 'pasillo-A-3'],
        'tipo': 'laboratorio',
        'capacidad': 25,
        'descripcion': 'Laboratorio de informática',
      },
      {
        'id': 'salon-A-303',
        'nombre': 'Salón A-303',
        'piso': 3,
        'torre': 'A',
        'x': 300.0,
        'y': 700.0,
        'conexiones': ['salon-A-302', 'pasillo-A-3'],
        'tipo': 'laboratorio',
        'capacidad': 25,
        'descripcion': 'Laboratorio de informática',
      },
      {
        'id': 'pasillo-A-3',
        'nombre': 'Pasillo Principal Torre A - Piso 3',
        'piso': 3,
        'torre': 'A',
        'x': 200.0,
        'y': 650.0,
        'conexiones': ['salon-A-301', 'salon-A-302', 'salon-A-303', 'escaleras-A-2-3'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },

      // ========== TORRE B ==========
      // Piso 1 - Torre B
      {
        'id': 'salon-B-101',
        'nombre': 'Salón B-101',
        'piso': 1,
        'torre': 'B',
        'x': 500.0,
        'y': 300.0,
        'conexiones': ['pasillo-B-1', 'salon-B-102'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-B-102',
        'nombre': 'Salón B-102',
        'piso': 1,
        'torre': 'B',
        'x': 600.0,
        'y': 300.0,
        'conexiones': ['salon-B-101', 'salon-B-103', 'pasillo-B-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-B-103',
        'nombre': 'Salón B-103',
        'piso': 1,
        'torre': 'B',
        'x': 700.0,
        'y': 300.0,
        'conexiones': ['salon-B-102', 'pasillo-B-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-B-1',
        'nombre': 'Pasillo Principal Torre B - Piso 1',
        'piso': 1,
        'torre': 'B',
        'x': 600.0,
        'y': 250.0,
        'conexiones': ['salon-B-101', 'salon-B-102', 'salon-B-103', 'escaleras-B-1-2', 'conexion-AB-1'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'conexion-AB-1',
        'nombre': 'Conexión Torre A-B (Piso 1)',
        'piso': 1,
        'torre': 'A-B',
        'x': 400.0,
        'y': 250.0,
        'conexiones': ['pasillo-A-1', 'pasillo-B-1'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Conexión entre torres',
      },
      {
        'id': 'escaleras-B-1-2',
        'nombre': 'Escaleras Torre B (Piso 1-2)',
        'piso': 1,
        'torre': 'B',
        'x': 550.0,
        'y': 200.0,
        'conexiones': ['pasillo-B-1', 'pasillo-B-2'],
        'tipo': 'escaleras',
        'capacidad': null,
        'descripcion': 'Escaleras entre pisos',
      },

      // Piso 2 - Torre B
      {
        'id': 'salon-B-201',
        'nombre': 'Salón B-201',
        'piso': 2,
        'torre': 'B',
        'x': 500.0,
        'y': 500.0,
        'conexiones': ['pasillo-B-2', 'salon-B-202'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-B-202',
        'nombre': 'Salón B-202',
        'piso': 2,
        'torre': 'B',
        'x': 600.0,
        'y': 500.0,
        'conexiones': ['salon-B-201', 'salon-B-203', 'pasillo-B-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-B-203',
        'nombre': 'Salón B-203',
        'piso': 2,
        'torre': 'B',
        'x': 700.0,
        'y': 500.0,
        'conexiones': ['salon-B-202', 'pasillo-B-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-B-2',
        'nombre': 'Pasillo Principal Torre B - Piso 2',
        'piso': 2,
        'torre': 'B',
        'x': 600.0,
        'y': 450.0,
        'conexiones': ['salon-B-201', 'salon-B-202', 'salon-B-203', 'escaleras-B-1-2', 'conexion-AB-2'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'conexion-AB-2',
        'nombre': 'Conexión Torre A-B (Piso 2)',
        'piso': 2,
        'torre': 'A-B',
        'x': 400.0,
        'y': 450.0,
        'conexiones': ['pasillo-A-2', 'pasillo-B-2'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Conexión entre torres',
      },

      // ========== TORRE C ==========
      // Piso 1 - Torre C
      {
        'id': 'salon-C-101',
        'nombre': 'Salón C-101',
        'piso': 1,
        'torre': 'C',
        'x': 900.0,
        'y': 300.0,
        'conexiones': ['pasillo-C-1', 'salon-C-102'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-C-102',
        'nombre': 'Salón C-102',
        'piso': 1,
        'torre': 'C',
        'x': 1000.0,
        'y': 300.0,
        'conexiones': ['salon-C-101', 'salon-C-103', 'pasillo-C-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-C-103',
        'nombre': 'Salón C-103',
        'piso': 1,
        'torre': 'C',
        'x': 1100.0,
        'y': 300.0,
        'conexiones': ['salon-C-102', 'pasillo-C-1'],
        'tipo': 'aula',
        'capacidad': 30,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-C-1',
        'nombre': 'Pasillo Principal Torre C - Piso 1',
        'piso': 1,
        'torre': 'C',
        'x': 1000.0,
        'y': 250.0,
        'conexiones': ['salon-C-101', 'salon-C-102', 'salon-C-103', 'escaleras-C-1-2', 'conexion-BC-1'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'conexion-BC-1',
        'nombre': 'Conexión Torre B-C (Piso 1)',
        'piso': 1,
        'torre': 'B-C',
        'x': 800.0,
        'y': 250.0,
        'conexiones': ['pasillo-B-1', 'pasillo-C-1'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Conexión entre torres',
      },
      {
        'id': 'escaleras-C-1-2',
        'nombre': 'Escaleras Torre C (Piso 1-2)',
        'piso': 1,
        'torre': 'C',
        'x': 950.0,
        'y': 200.0,
        'conexiones': ['pasillo-C-1', 'pasillo-C-2'],
        'tipo': 'escaleras',
        'capacidad': null,
        'descripcion': 'Escaleras entre pisos',
      },

      // Piso 2 - Torre C
      {
        'id': 'salon-C-201',
        'nombre': 'Salón C-201',
        'piso': 2,
        'torre': 'C',
        'x': 900.0,
        'y': 500.0,
        'conexiones': ['pasillo-C-2', 'salon-C-202'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-C-202',
        'nombre': 'Salón C-202',
        'piso': 2,
        'torre': 'C',
        'x': 1000.0,
        'y': 500.0,
        'conexiones': ['salon-C-201', 'salon-C-203', 'pasillo-C-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'salon-C-203',
        'nombre': 'Salón C-203',
        'piso': 2,
        'torre': 'C',
        'x': 1100.0,
        'y': 500.0,
        'conexiones': ['salon-C-202', 'pasillo-C-2'],
        'tipo': 'aula',
        'capacidad': 35,
        'descripcion': 'Aula de clases generales',
      },
      {
        'id': 'pasillo-C-2',
        'nombre': 'Pasillo Principal Torre C - Piso 2',
        'piso': 2,
        'torre': 'C',
        'x': 1000.0,
        'y': 450.0,
        'conexiones': ['salon-C-201', 'salon-C-202', 'salon-C-203', 'escaleras-C-1-2', 'conexion-BC-2'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Pasillo principal de acceso',
      },
      {
        'id': 'conexion-BC-2',
        'nombre': 'Conexión Torre B-C (Piso 2)',
        'piso': 2,
        'torre': 'B-C',
        'x': 800.0,
        'y': 450.0,
        'conexiones': ['pasillo-B-2', 'pasillo-C-2'],
        'tipo': 'pasillo',
        'capacidad': null,
        'descripcion': 'Conexión entre torres',
      },

      // ========== PUNTO INICIAL ==========
      {
        'id': 'punto-inicial',
        'nombre': 'Punto de Inicio',
        'piso': 0,
        'torre': 'Entrada',
        'x': 50.0,
        'y': 50.0,
        'conexiones': ['pasillo-A-1', 'pasillo-B-1'],
        'tipo': 'entrada',
        'capacidad': null,
        'descripcion': 'Punto de inicio de navegación',
      },
    ];
  }
}

