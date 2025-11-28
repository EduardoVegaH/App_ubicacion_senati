import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/domain/use_cases/load_student_with_courses_use_case.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/text_styles.dart';
import '../../../../app/styles/app_spacing.dart';

/// Página de identificación que muestra el carnet del estudiante
class IdentificationPage extends StatefulWidget {
  const IdentificationPage({super.key});

  @override
  State<IdentificationPage> createState() => _IdentificationPageState();
}

class _IdentificationPageState extends State<IdentificationPage> {
  final _loadStudentUseCase = sl<LoadStudentWithCoursesUseCase>();
  bool _loading = true;
  String _studentName = '';
  String _studentId = '';
  String _semester = '';
  String _career = '';
  String _school = '';
  String _campus = '';
  String _email = '';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final student = await _loadStudentUseCase.call();
      if (student != null && mounted) {
        setState(() {
          _studentName = student.name;
          _studentId = student.id;
          _semester = student.semester;
          _career = student.career;
          _school = student.school;
          _campus = student.zonalAddress;
          _email = student.institutionalEmail;
          _photoUrl = student.photoUrl;
          _loading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando datos del estudiante: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificación'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding(isLargePhone, isTablet),
              child: Center(
                child: _buildCarnet(isLargePhone, isTablet),
              ),
            ),
    );
  }

  Widget _buildCarnet(bool isLargePhone, bool isTablet) {
    return Container(
      width: isTablet ? 500 : (isLargePhone ? 400 : double.infinity),
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppStyles.primaryColor,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          // Header con logo SENATI
          Container(
            padding: EdgeInsets.all(isLargePhone ? 24 : 20),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SENATI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Carnet de Estudiante',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isLargePhone ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Contenido del carnet
          Padding(
            padding: EdgeInsets.all(isLargePhone ? 24 : 20),
            child: Column(
              children: [
                // Foto del estudiante
                Container(
                  width: isLargePhone ? 120 : 100,
                  height: isLargePhone ? 120 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppStyles.primaryColor,
                      width: 3,
                    ),
                    color: Colors.grey[200],
                  ),
                  child: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: isLargePhone ? 60 : 50,
                                color: AppStyles.primaryColor,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: isLargePhone ? 60 : 50,
                          color: AppStyles.primaryColor,
                        ),
                ),
                const SizedBox(height: 20),
                // Nombre
                Text(
                  _studentName,
                  style: TextStyle(
                    fontSize: isLargePhone ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Divider
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 16),
                // Información del estudiante
                _buildInfoRow(
                  'ID Estudiante',
                  _studentId,
                  Icons.badge,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Semestre',
                  _semester,
                  Icons.calendar_today,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Carrera',
                  _career,
                  Icons.school,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Escuela',
                  _school,
                  Icons.business,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Campus',
                  _campus,
                  Icons.location_on,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Email',
                  _email,
                  Icons.email,
                  isLargePhone,
                  isTablet,
                ),
                const SizedBox(height: 20),
                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        color: AppStyles.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Carnet Válido',
                        style: TextStyle(
                          color: AppStyles.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isLargePhone ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isLargePhone,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isLargePhone ? 20 : 18,
          color: AppStyles.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isLargePhone ? 12 : 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'No disponible',
                style: TextStyle(
                  fontSize: isLargePhone ? 15 : 14,
                  color: AppStyles.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

