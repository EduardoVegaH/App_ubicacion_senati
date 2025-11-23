import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';

/// Widget de encabezado con información del estudiante
class StudentInfoHeader extends StatelessWidget {
  final StudentEntity student;
  final String campusStatus; // "Dentro del campus" o "Fuera del campus"
  final VoidCallback? onMenuTap;
  final bool isLargePhone;
  final bool isTablet;

  const StudentInfoHeader({
    super.key,
    required this.student,
    required this.campusStatus,
    this.onMenuTap,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isLargePhone ? 20.0 : (isTablet ? 24.0 : 16.0);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B38E3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        top: isLargePhone ? 24 : (isTablet ? 28 : 20),
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de perfil + estado
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isLargePhone ? 64 : (isTablet ? 70 : 60),
                height: isLargePhone ? 64 : (isTablet ? 70 : 60),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                  image: student.photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(student.photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: student.photoUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: isLargePhone ? 42 : (isTablet ? 45 : 40),
                        color: const Color(0xFF757575),
                      )
                    : null,
              ),
              // Estado abajo derecha
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: campusStatus == "Dentro del campus"
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    campusStatus == "Dentro del campus" ? "Presente" : "Ausente",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isLargePhone ? 14 : (isTablet ? 16 : 12)),
          // Nombre, ID y Semestre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        student.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargePhone ? 17 : (isTablet ? 18 : 16),
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: isLargePhone ? 8 : (isTablet ? 10 : 6),
                    ),
                    // Icono de menú
                    if (onMenuTap != null)
                      GestureDetector(
                        onTap: onMenuTap,
                        child: Transform.translate(
                          offset: const Offset(0, -2),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: isLargePhone ? 6 : (isTablet ? 8 : 5),
                ),
                Text(
                  'ID: ${student.id}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                    height: 1.2,
                  ),
                ),
                SizedBox(
                  height: isLargePhone ? 8 : (isTablet ? 10 : 6),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student.semester,
                    style: TextStyle(
                      color: const Color(0xFF1B38E3),
                      fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
