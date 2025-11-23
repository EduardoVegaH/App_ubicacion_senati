import 'package:flutter/material.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../home/data/models/student_model.dart';

/// Card simple para mostrar un curso en la lista
class SimpleCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final bool isLargePhone;
  final bool isTablet;

  const SimpleCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: AppSpacing.cardPaddingLarge(isLargePhone, isTablet),
        child: Row(
          children: [
            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del curso
                  Text(
                    course.name,
                    style: AppTextStyles.titleMedium(isLargePhone, isTablet),
                  ),
                  const SizedBox(height: 4),
                  // Nombre del docente (subtítulo)
                  Text(
                    course.teacher,
                    style: AppTextStyles.bodyTiny(isLargePhone, isTablet),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Icono de navegación
            Icon(
              Icons.arrow_forward_ios,
              size: isLargePhone ? 18 : (isTablet ? 20 : 16),
              color: const Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }
}

