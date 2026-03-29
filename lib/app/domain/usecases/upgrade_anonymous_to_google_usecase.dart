import '../../data/auth_repository.dart';

class UpgradeAnonymousToGoogleUseCase {
  UpgradeAnonymousToGoogleUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> call() {
    return _authRepository.linkWithGoogle();
  }
}
