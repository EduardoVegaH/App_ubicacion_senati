import '../repositories/home_repository.dart';
import '../entities/student_entity.dart';

/// Use case para obtener datos del estudiante
class GetStudentDataUseCase {
  final HomeRepository _repository;

  GetStudentDataUseCase(this._repository);

  Future<StudentEntity?> call() async {
    return await _repository.getStudentData();
  }
}

