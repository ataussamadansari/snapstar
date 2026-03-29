import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

class ObserveAuthStateUseCase {
  ObserveAuthStateUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Stream<AuthState> call() {
    return _authRepository.authStateChanges;
  }
}
