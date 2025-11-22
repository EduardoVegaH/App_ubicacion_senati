import '../../domain/entities/friend_entity.dart';

/// Modelo de datos de amigo (con serialización)
class FriendModel extends FriendEntity {
  FriendModel({
    required super.uid,
    required super.name,
    required super.id,
    required super.photoUrl,
    required super.status,
    super.latitude,
    super.longitude,
    super.lastUpdate,
  });

  /// Crear desde Firestore
  factory FriendModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return FriendModel(
      uid: uid,
      name: data['NameEstudent'] ?? '',
      id: data['IdEstudiante'] ?? '',
      photoUrl: data['foto'] ?? '',
      status: data['estado'] ?? 'Desconocido',
      latitude: data['lat']?.toDouble(),
      longitude: data['lon']?.toDouble(),
      lastUpdate: data['timestamp'] != null 
          ? DateTime.tryParse(data['timestamp']) 
          : null,
    );
  }

  /// Convertir a entidad
  FriendEntity toEntity() {
    return FriendEntity(
      uid: uid,
      name: name,
      id: id,
      photoUrl: photoUrl,
      status: status,
      latitude: latitude,
      longitude: longitude,
      lastUpdate: lastUpdate,
    );
  }
}

