import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTestData() async {
    await _db.collection('test').add({
      'mensaje': 'Hola desde Flutter 👋',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
