import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';
import 'section_header.dart';
import 'info_row.dart';

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
        SectionHeader(
          icon: Icons.school,
          title: 'Información Académica',
          iconColor: const Color(0xFF1B38E3),
          bottomSpacing: isLargePhone ? 22 : (isTablet ? 24 : 20),
        ),
        // Dirección Zonal
        InfoRow(
          label: 'Dirección Zonal',
          value: student.zonalAddress,
          bottomSpacing: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Escuela
        InfoRow(
          label: 'Escuela',
          value: student.school,
          bottomSpacing: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Carrera
        InfoRow(
          label: 'Carrera',
          value: student.career,
          bottomSpacing: isLargePhone ? 18 : (isTablet ? 20 : 16),
        ),
        // Correo Institucional
        InfoRow(
          label: 'Correo Institucional',
          value: student.institutionalEmail,
        ),
      ],
    );
  }
}

