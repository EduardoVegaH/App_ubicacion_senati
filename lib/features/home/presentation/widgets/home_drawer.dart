import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../domain/entities/student_entity.dart';
import '../../../bathrooms/presentation/pages/bathroom_status_page.dart';
import '../../../friends/presentation/pages/friends_page.dart';
import '../../../chatbot/presentation/pages/chatbot_page.dart';
import '../../presentation/pages/courses_list_page.dart';
import '../../data/models/student_model.dart';

/// Widget para el drawer lateral
class HomeDrawer extends StatelessWidget {
  final StudentEntity? student;
  final VoidCallback onLogout;
  final bool isLargePhone;
  final bool isTablet;

  const HomeDrawer({
    super.key,
    this.student,
    required this.onLogout,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.primaryColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header del drawer
              Container(
                padding: EdgeInsets.all(
                  isLargePhone ? 20 : (isTablet ? 24 : 16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Menú',
                        style: TextStyle(
                          color: AppStyles.textOnDark,
                          fontSize: isLargePhone ? 24 : (isTablet ? 26 : 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppStyles.textOnDark,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Separador
              Divider(
                color: AppStyles.textOnDark.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 8),
              // Opciones del menú
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                    vertical: 8,
                  ),
                  children: [
                    // Botón Baños
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.wc,
                      title: 'Baños',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BathroomStatusPage(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    // Separador
                    Divider(
                      color: AppStyles.textOnDark.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    // Botón Cursos
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.folder,
                      title: 'Cursos',
                      onTap: () {
                        Navigator.pop(context);
                        if (student != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoursesListPage(
                                courses: student!.coursesToday.map((c) {
                                  return CourseModel(
                                    name: c.name,
                                    type: c.type,
                                    startTime: c.startTime,
                                    endTime: c.endTime,
                                    duration: c.duration,
                                    teacher: c.teacher,
                                    locationCode: c.locationCode,
                                    locationDetail: c.locationDetail,
                                    classroomLatitude: c.classroomLatitude,
                                    classroomLongitude: c.classroomLongitude,
                                    classroomRadius: c.classroomRadius,
                                    history: c.history,
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    // Separador
                    Divider(
                      color: AppStyles.textOnDark.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    // Botón Amigos
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people,
                      title: 'Amigos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsPage(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    // Separador
                    Divider(
                      color: AppStyles.textOnDark.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    // Botón Asistente Virtual (Chatbot)
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.smart_toy,
                      title: 'Asistente Virtual',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatbotPage(),
                          ),
                        );
                      },
                      isLargePhone: isLargePhone,
                      isTablet: isTablet,
                    ),
                    // Separador
                    Divider(
                      color: AppStyles.textOnDark.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                      indent: isLargePhone ? 56 : (isTablet ? 60 : 52),
                    ),
                    // Botón Administración de Salones (opcional, comentado por ahora)
                    // _buildDrawerItem(
                    //   context: context,
                    //   icon: Icons.admin_panel_settings,
                    //   title: 'Administración de Salones',
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     // TODO: Implementar navegación a administración de salones
                    //   },
                    //   isLargePhone: isLargePhone,
                    //   isTablet: isTablet,
                    // ),
                  ],
                ),
              ),
              // Separador antes de cerrar sesión
              Divider(
                color: AppStyles.textOnDark.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 8),
              // Botón Cerrar Sesión
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                  vertical: 8,
                ),
                child: _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  isLargePhone: isLargePhone,
                  isTablet: isTablet,
                  isLogout: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isLargePhone,
    required bool isTablet,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
          vertical: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red.shade300 : AppStyles.textOnDark,
              size: isLargePhone ? 24 : (isTablet ? 26 : 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isLogout ? Colors.red.shade300 : AppStyles.textOnDark,
                  fontSize: isLargePhone ? 16 : (isTablet ? 18 : 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isLogout
                  ? Colors.red.shade300
                  : AppStyles.textOnDark.withOpacity(0.7),
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
            ),
          ],
        ),
      ),
    );
  }
}

