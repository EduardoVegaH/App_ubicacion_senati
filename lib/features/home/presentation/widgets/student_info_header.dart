import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../domain/entities/student_entity.dart';

/// Widget para el header con información del estudiante
class StudentInfoHeader extends StatelessWidget {
  final StudentEntity student;
  final String campusStatus;
  final bool isLargePhone;
  final bool isTablet;

  const StudentInfoHeader({
    super.key,
    required this.student,
    required this.campusStatus,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLargePhone ? 20 : (isTablet ? 24 : 16)),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Foto del estudiante
              CircleAvatar(
                radius: isLargePhone ? 30 : (isTablet ? 32 : 28),
                backgroundColor: AppStyles.surfaceColor,
                backgroundImage: student.photoUrl.isNotEmpty
                    ? NetworkImage(student.photoUrl)
                    : null,
                child: student.photoUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: isLargePhone ? 30 : (isTablet ? 32 : 28),
                        color: AppStyles.primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Nombre y ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: isLargePhone ? 20 : (isTablet ? 22 : 18),
                        fontWeight: FontWeight.bold,
                        color: AppStyles.textOnDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${student.id}',
                      style: TextStyle(
                        fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                        color: AppStyles.textOnDark.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Estado del campus
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargePhone ? 12 : (isTablet ? 14 : 10),
              vertical: isLargePhone ? 8 : (isTablet ? 10 : 6),
            ),
            decoration: BoxDecoration(
              color: AppStyles.surfaceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  campusStatus == "Dentro del campus"
                      ? Icons.location_on
                      : Icons.location_off,
                  size: isLargePhone ? 18 : (isTablet ? 20 : 16),
                  color: AppStyles.textOnDark,
                ),
                const SizedBox(width: 6),
                Text(
                  campusStatus,
                  style: TextStyle(
                    fontSize: isLargePhone ? 14 : (isTablet ? 15 : 13),
                    fontWeight: FontWeight.w500,
                    color: AppStyles.textOnDark,
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

