import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/usecases/login_anonymously_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/observe_auth_state_usecase.dart';
import '../../domain/usecases/upgrade_anonymous_to_google_usecase.dart';

class AuthController extends GetxController {
  AuthController({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required LoginAnonymouslyUseCase loginAnonymouslyUseCase,
    required LogoutUseCase logoutUseCase,
    required UpgradeAnonymousToGoogleUseCase upgradeAnonymousToGoogleUseCase,
    required ObserveAuthStateUseCase observeAuthStateUseCase,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _loginWithGoogleUseCase = loginWithGoogleUseCase,
       _loginAnonymouslyUseCase = loginAnonymouslyUseCase,
       _logoutUseCase = logoutUseCase,
       _upgradeAnonymousToGoogleUseCase = upgradeAnonymousToGoogleUseCase,
       _observeAuthStateUseCase = observeAuthStateUseCase;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final LoginAnonymouslyUseCase _loginAnonymouslyUseCase;
  final LogoutUseCase _logoutUseCase;
  final UpgradeAnonymousToGoogleUseCase _upgradeAnonymousToGoogleUseCase;
  final ObserveAuthStateUseCase _observeAuthStateUseCase;

  final Rxn<User> currentUser = Rxn<User>();
  final Rxn<UserModel> currentUserProfile = Rxn<UserModel>();
  final RxBool isAnonymous = false.obs;
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxnString authError = RxnString();

  StreamSubscription<AuthState>? _authSubscription;

  User? get user => currentUser.value;
  UserModel? get userProfile => currentUserProfile.value;
  String? get currentUserId => _authRepository.currentUserId;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromCurrentSession();
    _listenToAuthState();
  }

  Future<void> ensureSession() async {
    if (_authRepository.hasSession) {
      await _applySession(_authRepository.currentSession);
      return;
    }

    await loginAnonymously();
  }

  Future<void> loginWithGoogle() async {
    if (_authRepository.hasSession && !_authRepository.isAnonymous) {
      await _applySession(_authRepository.currentSession);
      return;
    }

    await _runAuthAction(() async {
      if (isAnonymous.value) {
        await _linkAnonymousUserWithGoogle();
        return;
      }

      final response = await _loginWithGoogleUseCase();
      final signedInUser = response.user;
      if (signedInUser != null) {
        await _syncGoogleUser(signedInUser);
      }
    });
  }

  Future<void> loginAnonymously() async {
    if (_authRepository.hasSession) {
      await _applySession(_authRepository.currentSession);
      return;
    }

    await _runAuthAction(() async {
      await _loginAnonymouslyUseCase();
    });
  }

  Future<void> logout() async {
    await _runAuthAction(() async {
      await _logoutUseCase();
      currentUser.value = null;
      currentUserProfile.value = null;
      isAnonymous.value = false;
      isLoggedIn.value = false;
    });
  }

  Future<void> upgradeAnonymousToGoogle() async {
    await _runAuthAction(() async {
      await _linkAnonymousUserWithGoogle();
    });
  }

  Future<void> refreshUserProfile() async {
    final userId = currentUserId;
    if (userId == null || isAnonymous.value) {
      currentUserProfile.value = null;
      return;
    }

    try {
      currentUserProfile.value = await _userRepository.fetchProfile(userId);
    } catch (error, stackTrace) {
      debugPrint('AuthController.refreshUserProfile error: $error');
      debugPrint('AuthController.refreshUserProfile stack: $stackTrace');
    }
  }

  void _hydrateFromCurrentSession() {
    currentUser.value = _authRepository.currentUser;
    isLoggedIn.value = _authRepository.isLoggedIn;
    isAnonymous.value = _authRepository.isAnonymous;

    if (isLoggedIn.value && !isAnonymous.value) {
      unawaited(refreshUserProfile());
    }
  }

  void _listenToAuthState() {
    _authSubscription = _observeAuthStateUseCase().listen(
      (authState) async {
        await _applySession(authState.session, event: authState.event);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AuthController.authState error: $error');
        debugPrint('AuthController.authState stack: $stackTrace');
      },
    );
  }

  Future<void> _applySession(
    Session? session, {
    AuthChangeEvent? event,
  }) async {
    final sessionUser = session?.user;

    currentUser.value = sessionUser;
    isLoggedIn.value = sessionUser != null;
    isAnonymous.value = sessionUser?.isAnonymous ?? false;

    if (sessionUser == null) {
      currentUserProfile.value = null;
      return;
    }

    if (isAnonymous.value) {
      await _syncAnonymousUser(sessionUser);
      return;
    }

    if (event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed ||
        event == AuthChangeEvent.userUpdated ||
        currentUserProfile.value == null) {
      await _syncGoogleUser(sessionUser);
      return;
    }

    await refreshUserProfile();
  }

  Future<void> _syncGoogleUser(User supabaseUser) async {
    final existingProfile =
        currentUserProfile.value ??
        await _userRepository.fetchProfile(supabaseUser.id);
    final metadata = supabaseUser.userMetadata ?? <String, dynamic>{};
    final email = supabaseUser.email ?? '';
    final username = _buildUsername(
      metadata['user_name']?.toString(),
      metadata['preferred_username']?.toString(),
      email,
      supabaseUser.id,
    );
    final now = DateTime.now();

    final profile = UserModel(
      id: supabaseUser.id,
      name:
          metadata['full_name']?.toString() ??
          metadata['name']?.toString() ??
          username,
      username: username,
      email: email,
      avatarUrl:
          existingProfile?.avatarUrl?.trim().isNotEmpty == true
          ? existingProfile!.avatarUrl
          : metadata['avatar_url']?.toString() ??
                metadata['picture']?.toString(),
      phone: metadata['phone_number']?.toString(),
      bio: existingProfile?.bio,
      role: existingProfile?.role ?? 'user',
      postsCount: existingProfile?.postsCount ?? 0,
      subscriberCount: existingProfile?.subscriberCount ?? 0,
      subscribingCount: existingProfile?.subscribingCount ?? 0,
      isAnonymous: false,
      createdAt: existingProfile?.createdAt ?? now,
      updatedAt: now,
    );

    await _userRepository.createProfile(profile);
    await refreshUserProfile();
  }

  Future<void> _syncAnonymousUser(User supabaseUser) async {
    final existingProfile = await _userRepository.fetchProfile(supabaseUser.id);
    final now = DateTime.now();

    final profile = UserModel(
      id: supabaseUser.id,
      name: existingProfile?.name.isNotEmpty == true
          ? existingProfile!.name
          : 'Guest',
      username: existingProfile?.username.isNotEmpty == true
          ? existingProfile!.username
          : 'guest_${supabaseUser.id.substring(0, 8)}',
      email:
          (existingProfile?.email.trim().isNotEmpty == true)
          ? existingProfile!.email
          : 'guest_${supabaseUser.id}@guest.snapstar.local',
      avatarUrl: existingProfile?.avatarUrl,
      phone: existingProfile?.phone,
      bio: existingProfile?.bio,
      role: existingProfile?.role ?? 'user',
      isAnonymous: true,
      postsCount: existingProfile?.postsCount ?? 0,
      subscriberCount: existingProfile?.subscriberCount ?? 0,
      subscribingCount: existingProfile?.subscribingCount ?? 0,
      createdAt: existingProfile?.createdAt ?? now,
      updatedAt: now,
    );

    await _userRepository.createProfile(profile);
    currentUserProfile.value = profile;
  }

  Future<void> _linkAnonymousUserWithGoogle() async {
    User? linkedUser;

    try {
      final linked = await _upgradeAnonymousToGoogleUseCase();
      if (!linked) {
        throw const AuthException('Google account could not be linked.');
      }

      linkedUser = _authRepository.currentUser;
    } on AuthApiException catch (error) {
      if (error.code != 'manual_linking_disabled') {
        rethrow;
      }

      // Fallback when Supabase identity linking is disabled:
      // sign in with Google directly so the user can continue.
      final response = await _loginWithGoogleUseCase();
      linkedUser = response.user;
    }

    if (linkedUser == null) {
      throw const AuthException('Google sign-in did not return a user.');
    }

    await _syncGoogleUser(linkedUser);
  }

  String _buildUsername(
    String? explicitUsername,
    String? preferredUsername,
    String email,
    String userId,
  ) {
    final candidates = <String?>[
      explicitUsername,
      preferredUsername,
      email.isNotEmpty ? email.split('@').first : null,
    ];

    for (final candidate in candidates) {
      final normalized = candidate
          ?.trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_.]'), '');
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return 'user_${userId.substring(0, 8)}';
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    authError.value = null;
    isLoading.value = true;

    try {
      await action();
    } on AuthException catch (error) {
      authError.value = error.message;
      Get.snackbar('Authentication failed', error.message);
    } on PostgrestException catch (error) {
      authError.value = error.message;
      Get.snackbar('Database error', error.message);
    } catch (error) {
      authError.value = error.toString();
      Get.snackbar('Authentication failed', error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
