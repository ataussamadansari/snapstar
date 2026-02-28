import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  final RxBool isLoading = false.obs;
  final Rxn<User> user = Rxn<User>();

  StreamSubscription<User?>? _authSubscription;

  String? get currentUserId => _authRepository.currentUserId;
  bool get isLoggedIn => currentUserId != null;

  @override
  void onInit() {
    super.onInit();

    user.value = _authRepository.currentUser;
    _authSubscription = _authRepository.currentUserStream.listen((currentUser) {
      user.value = currentUser;
    });
  }

  Future<void> signup(String email, String password) async {
    isLoading.value = true;
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      await _authRepository.signIn(
        email: email,
        password: password,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() {
    return _authRepository.signOut();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
