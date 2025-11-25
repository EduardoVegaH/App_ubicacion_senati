// Script de utilidad para inicializar baños de ejemplo en Firebase
// Este archivo puede ser ejecutado manualmente o desde la consola de Firebase
// 
// Para usar este script, puedes crear una función en tu app o ejecutarlo desde
// la consola de Firebase con datos de ejemplo.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/bathrooms/domain/entities/bathroom_entity.dart';

class BathroomInitializer {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Exponer _db para uso externo
  FirebaseFirestore get db => _db;

  // Inicializar baños de ejemplo
  Future<void> initializeSampleBathrooms() async {
    final sampleBathrooms = [
      // Piso 7
      {
        'nombre': 'Baño Hombres 7mo Piso',
        'piso': 7,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'hombres',
      },
      {
        'nombre': 'Baño Mujeres 7mo Piso',
        'piso': 7,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'mujeres',
      },
      // Piso 6
      {
        'nombre': 'Baño Hombres 6to Piso',
        'piso': 6,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'hombres',
      },
      {
        'nombre': 'Baño Mujeres 6to Piso',
        'piso': 6,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'mujeres',
      },
      // Piso 5 - En limpieza para MVP
      {
        'nombre': 'Baño Hombres 5to Piso',
        'piso': 5,
        'estado': BathroomStatus.en_limpieza.toString().split('.').last,
        'tipo': 'hombres',
      },
      {
        'nombre': 'Baño Mujeres 5to Piso',
        'piso': 5,
        'estado': BathroomStatus.en_limpieza.toString().split('.').last,
        'tipo': 'mujeres',
      },
      // Piso 4
      {
        'nombre': 'Baño Hombres 4to Piso',
        'piso': 4,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'hombres',
      },
      {
        'nombre': 'Baño Mujeres 4to Piso',
        'piso': 4,
        'estado': BathroomStatus.operativo.toString().split('.').last,
        'tipo': 'mujeres',
      },
      // Piso 3 - En limpieza para MVP
      {
        'nombre': 'Baño Hombres 3er Piso',
        'piso': 3,
        'estado': BathroomStatus.en_limpieza.toString().split('.').last,
        'tipo': 'hombres',
      },
      {
        'nombre': 'Baño Mujeres 3er Piso',
        'piso': 3,
        'estado': BathroomStatus.en_limpieza.toString().split('.').last,
        'tipo': 'mujeres',
      },
    ];

    final batch = _db.batch();

    for (var bathroomData in sampleBathrooms) {
      final docRef = _db.collection('bathrooms').doc();
      batch.set(docRef, {
        ...bathroomData,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Limpiar todos los baños (usar con precaución)
  Future<void> clearAllBathrooms() async {
    final snapshot = await _db.collection('bathrooms').get();
    final batch = _db.batch();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Actualizar estados de baños existentes (para pisos 3 y 5)
  Future<void> updateBathroomsToCleaning() async {
    final snapshot = await _db.collection('bathrooms').get();
    final batch = _db.batch();
    int updated = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final piso = data['piso'];
      
      // Actualizar pisos 3 y 5 a "en_limpieza"
      if (piso == 3 || piso == 5) {
        batch.update(doc.reference, {
          'estado': BathroomStatus.en_limpieza.toString().split('.').last,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
        updated++;
      }
    }

    if (updated > 0) {
      await batch.commit();
    }
  }
}

// Para ejecutar desde la consola de Firebase o desde una función:
// 
// import 'package:your_app/utils/initialize_bathrooms.dart';
// 
// final initializer = BathroomInitializer();
// await initializer.initializeSampleBathrooms();

