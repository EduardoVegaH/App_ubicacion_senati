class Friend {
  final String uid;
  final String name;
  final String id;
  final String photoUrl;
  final String status; // "Dentro del campus" o "Fuera del campus"
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdate;

  Friend({
    required this.uid,
    required this.name,
    required this.id,
    required this.photoUrl,
    required this.status,
    this.latitude,
    this.longitude,
    this.lastUpdate,
  });

  factory Friend.fromFirestore(Map<String, dynamic> data, String uid) {
    return Friend(
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

  bool get isPresent => status == "Dentro del campus";
}

