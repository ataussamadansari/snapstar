import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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
  Stream<AuthState> get authStateChanges => _provider.authStateChanges;
  bool get isAnonymous => _provider.isAnonymous;

  Future<AuthResponse> signInWithGoogle() async {
    try {
      return await _provider.signInWithGoogle();
    } catch (error, stackTrace) {
      debugPrint('AuthService.signInWithGoogle error: $error');
      debugPrint('AuthService.signInWithGoogle stack: $stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> signInAnonymously() async {
    try {
      return await _provider.signInAnonymously();
    } catch (error, stackTrace) {
      debugPrint('AuthService.signInAnonymously error: $error');
      debugPrint('AuthService.signInAnonymously stack: $stackTrace');
      rethrow;
    }
  }

  Future<bool> linkWithGoogle() async {
    try {
      return await _provider.linkWithGoogle();
    } catch (error, stackTrace) {
      debugPrint('AuthService.linkWithGoogle error: $error');
      debugPrint('AuthService.linkWithGoogle stack: $stackTrace');
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

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _currentUserController.close();
    super.onClose();
  }
}
