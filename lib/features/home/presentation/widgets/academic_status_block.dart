import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';

/// Widget de bloque de información académica
class AcademicStatusBlock extends StatelessWidget {
  final StudentEntity student;

  const AcademicStatusBlock({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con icono
        Row(
          children: [
            Icon(
              Icons.school,
              color: const Color(0xFF1B38E3),
              size: isLargePhone ? 26 : (isTablet ? 28 : 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Información Académica',
              style: TextStyle(
                fontSize: isLargePhone ? 20 : (isTablet ? 22 : 18),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        SizedBox(
          height: isLargePhone ? 22 : (isTablet ? 24 : 20),
        ),
        // Dirección Zonal
        _buildInfoRow(
          'Dirección Zonal',
          student.zonalAddress,
          isLargePhone,
          isTablet,
        ),
        SizedBox(
          height: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Escuela
        _buildInfoRow(
          'Escuela',
          student.school,
          isLargePhone,
          isTablet,
        ),
        SizedBox(
          height: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Carrera
        _buildInfoRow(
          'Carrera',
          student.career,
          isLargePhone,
          isTablet,
        ),
        SizedBox(
          height: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Correo Institucional
        _buildInfoRow(
          'Correo Institucional',
          student.institutionalEmail,
          isLargePhone,
          isTablet,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isLargePhone,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLargePhone ? 15 : (isTablet ? 16 : 14),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C2C2C),
            ),
          ),
        ),
      ],
    );
  }
}

