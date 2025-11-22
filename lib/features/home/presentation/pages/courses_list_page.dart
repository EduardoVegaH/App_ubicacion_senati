import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../data/models/student_model.dart';
import 'course_history_page.dart';

/// Página de lista de cursos
class CoursesListPage extends StatelessWidget {
  final List<CourseModel> courses;

  const CoursesListPage({
    super.key,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 20 : 14)),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
            ),
            child: _buildSimpleCourseCard(
              context,
              course,
              isLargePhone,
              isTablet,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimpleCourseCard(
    BuildContext context,
    CourseModel course,
    bool isLargePhone,
    bool isTablet,
  ) {
    return InkWell(
      onTap: () {
        // Navegar al historial del curso
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseHistoryPage(course: course),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusM),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.surfaceColor,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusM),
        ),
        padding: EdgeInsets.all(isLargePhone ? 18 : (isTablet ? 20 : 16)),
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
                    style: TextStyle(
                      fontSize: isLargePhone ? 18 : (isTablet ? 20 : 16),
                      fontWeight: FontWeight.bold,
                      color: AppStyles.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nombre del docente (subtítulo)
                  Text(
                    course.teacher,
                    style: TextStyle(
                      fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                      color: AppStyles.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
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
              color: AppStyles.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
