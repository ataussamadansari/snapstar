import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  User? get currentUser => _service.currentUser;
  Session? get currentSession => _service.currentSession;
  String? get currentUserId => currentUser?.id;
  bool get hasSession => currentSession != null;
  bool get isAnonymous => _service.isAnonymous;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> get currentUserStream => _service.currentUserStream;
  Stream<AuthState> get authStateChanges => _service.authStateChanges;

  Future<AuthResponse> signInWithGoogle() => _service.signInWithGoogle();

  Future<AuthResponse> signInAnonymously() => _service.signInAnonymously();

  Future<bool> linkWithGoogle() => _service.linkWithGoogle();

  Future<void> signOut() => _service.signOut();
}
