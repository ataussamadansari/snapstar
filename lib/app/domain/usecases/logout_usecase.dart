import '../../data/auth_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() {
    return _authRepository.signOut();
  }
}
