import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/avatar_with_badge/avatar_with_badge.dart';

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
    final isPresent = campusStatus == "Dentro del campus";

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
          AvatarWithBadge(
            photoUrl: student.photoUrl,
            badgeText: isPresent ? "Presente" : "Ausente",
            badgeColor: isPresent ? Colors.green : Colors.red,
            size: isLargePhone ? 64 : (isTablet ? 70 : 60),
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
                        style: AppTextStyles.studentName(isLargePhone, isTablet),
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
                  style: AppTextStyles.studentId(isLargePhone, isTablet),
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
                    style: AppTextStyles.studentSemester(isLargePhone, isTablet),
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
