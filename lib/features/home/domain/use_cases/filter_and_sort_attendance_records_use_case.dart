import '../entities/attendance_entity.dart';

/// Use case para filtrar y ordenar registros de asistencia
class FilterAndSortAttendanceRecordsUseCase {
  /// Filtrar y ordenar registros de asistencia
  /// 
  /// [records] - Lista de registros a filtrar y ordenar
  /// [filter] - Estado de filtro (null = todos, o un estado específico)
  /// 
  /// Retorna lista filtrada y ordenada por fecha (más recientes primero)
  List<AttendanceRecordEntity> call({
    required List<AttendanceRecordEntity> records,
    AttendanceStatus? filter,
  }) {
    // Filtrar registros según el filtro seleccionado
    List<AttendanceRecordEntity> filteredRecords = records;
    if (filter != null) {
      filteredRecords = records
          .where((record) => record.status == filter)
          .toList();
    }

    // Ordenar registros por fecha (más recientes primero)
    final sortedRecords = List<AttendanceRecordEntity>.from(filteredRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedRecords;
  }
}

