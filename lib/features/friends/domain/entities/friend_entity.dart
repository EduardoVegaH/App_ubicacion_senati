/// Entidad de amigo (sin dependencias externas)
class FriendEntity {
  final String uid;
  final String name;
  final String id;
  final String photoUrl;
  final String status; // "Dentro del campus" o "Fuera del campus"
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdate;

  FriendEntity({
    required this.uid,
    required this.name,
    required this.id,
    required this.photoUrl,
    required this.status,
    this.latitude,
    this.longitude,
    this.lastUpdate,
  });

  bool get isPresent => status == "Dentro del campus";
}

