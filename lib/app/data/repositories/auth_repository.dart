import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  User? get currentUser => _service.currentUser;
  Session? get currentSession => _service.currentSession;
  String? get currentUserId => _service.currentUser?.id;
  bool get hasSession => currentSession != null;
  Stream<User?> get currentUserStream => _service.currentUserStream;

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _service.signUp(
      email: email,
      password: password,
    );
    return response.user?.id;
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _service.signIn(
      email: email,
      password: password,
    );
    return response.user?.id;
  }

  Future<void> signOut() {
    return _service.signOut();
  }
}
