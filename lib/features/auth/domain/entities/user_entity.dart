/// Entidad de usuario (sin dependencias externas)
class UserEntity {
  final String uid;
  final String email;
  final String? name;
  final String? studentId;
  final String? semester;
  
  UserEntity({
    required this.uid,
    required this.email,
    this.name,
    this.studentId,
    this.semester,
  });
}

