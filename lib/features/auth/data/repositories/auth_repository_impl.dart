import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  
  AuthRepositoryImpl(this._dataSource);
  
  @override
  Future<UserEntity?> login(String email, String password) async {
    final userModel = await _dataSource.login(email, password);
    return userModel?.toEntity();
  }
  
  @override
  Future<UserEntity?> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String semester,
  }) async {
    final userModel = await _dataSource.register(
      email: email,
      password: password,
      name: name,
      studentId: studentId,
      semester: semester,
    );
    return userModel?.toEntity();
  }
  
  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }
  
  @override
  UserEntity? getCurrentUser() {
    final userModel = _dataSource.getCurrentUser();
    return userModel?.toEntity();
  }
  
  @override
  Stream<UserEntity?> getAuthStateChanges() {
    return _dataSource.getAuthStateChanges().map((userModel) => userModel?.toEntity());
  }
}

