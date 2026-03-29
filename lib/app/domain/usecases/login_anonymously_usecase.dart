import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

class LoginAnonymouslyUseCase {
  LoginAnonymouslyUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthResponse> call() {
    return _authRepository.signInAnonymously();
  }
}
