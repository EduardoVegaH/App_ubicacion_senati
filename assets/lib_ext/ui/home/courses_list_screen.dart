import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import 'course_history_screen.dart';

class CoursesListScreen extends StatelessWidget {
  final List<Course> courses;

  const CoursesListScreen({
    super.key,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Mis Cursos'),
        backgroundColor: const Color(0xFF1B38E3),
        foregroundColor: Colors.white,
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
    Course course,
    bool isLargePhone,
    bool isTablet,
  ) {
    return InkWell(
      onTap: () {
        // Navegar al historial del curso
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseHistoryScreen(course: course),
          ),
        );
      },
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
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nombre del docente (subtítulo)
                  Text(
                    course.teacher,
                    style: TextStyle(
                      fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                      color: const Color(0xFF757575),
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
              color: const Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }

}

