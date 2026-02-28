import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

class AuthService extends GetxService {
  AuthService(this._provider) {
    _currentUserController.add(_provider.currentUser);
    _authStateSubscription = _provider.authStateChanges.listen(
      (authState) {
        _currentUserController.add(authState.session?.user);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AuthService.authStateChanges error: $error');
        debugPrint('AuthService.authStateChanges stack: $stackTrace');
      },
    );
  }

  final AuthProvider _provider;
  final StreamController<User?> _currentUserController =
      StreamController<User?>.broadcast();

  StreamSubscription<AuthState>? _authStateSubscription;

  User? get currentUser => _provider.currentUser;
  Session? get currentSession => _provider.currentSession;
  Stream<User?> get currentUserStream => _currentUserController.stream;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _provider.signUp(
        email: email,
        password: password,
      );
    } catch (error, stackTrace) {
      debugPrint('AuthService.signUp error: $error');
      debugPrint('AuthService.signUp stack: $stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _provider.signIn(
        email: email,
        password: password,
      );
    } catch (error, stackTrace) {
      debugPrint('AuthService.signIn error: $error');
      debugPrint('AuthService.signIn stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _provider.signOut();
    } catch (error, stackTrace) {
      debugPrint('AuthService.signOut error: $error');
      debugPrint('AuthService.signOut stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    await _currentUserController.close();
  }
}
