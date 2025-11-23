import 'package:flutter/material.dart';
import '../../../home/data/models/student_model.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../../../core/widgets/empty_states/index.dart';
import '../widgets/simple_course_card.dart';
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
      appBar: const AppBarWithTitle(
        title: 'Mis Cursos',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: courses.isEmpty
          ? EmptyState(
              icon: Icons.school_outlined,
              message: 'No hay cursos disponibles',
            )
          : ListView.builder(
              padding: AppSpacing.cardPaddingMedium(isLargePhone, isTablet),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
                  ),
                  child: SimpleCourseCard(
                    course: course,
                    isLargePhone: isLargePhone,
                    isTablet: isTablet,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseHistoryPage(course: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
