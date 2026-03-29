import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider {
  AuthProvider(this._client);

  final SupabaseClient _client;

  // ─── Getters ────────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Returns true when the current session belongs to an anonymous user.
  /// Supabase marks anonymous users with is_anonymous = true in the JWT.
  bool get isAnonymous =>
      currentUser?.isAnonymous ?? false;

  GoogleSignIn _buildGoogleSignIn() {
    final webClientId =
        dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
        dotenv.env['WEB_CLIENT_ID'] ??
        '';
    final iosClientId = dotenv.env['IOS_CLIENT_ID'] ?? '';

    return GoogleSignIn(
      // Android needs the web client id to mint a usable idToken for Supabase.
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
      // iOS is more reliable when the platform client id is provided explicitly.
      clientId: defaultTargetPlatform == TargetPlatform.iOS &&
              iosClientId.isNotEmpty
          ? iosClientId
          : null,
    );
  }

  // ─── Google Sign-In ─────────────────────────────────────────────────────────

  /// Signs in with Google via Supabase OAuth.
  /// Uses [GoogleSignIn] to obtain the id token, then passes it to Supabase.
  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = _buildGoogleSignIn();

    final googleUser = await googleSignIn.signIn().onError((error, stackTrace) {
      debugPrint('AuthProvider.signInWithGoogle GoogleSignIn error: $error');
      throw _mapGoogleError(error ?? Exception('Unknown Google sign-in error'));
    });
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled by user.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Google id token is null.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ─── Anonymous Sign-In ───────────────────────────────────────────────────────

  /// Creates an anonymous Supabase session (no credentials required).
  Future<AuthResponse> signInAnonymously() async {
    return _client.auth.signInAnonymously();
  }

  // ─── Upgrade anonymous → Google ─────────────────────────────────────────────

  /// Links the current anonymous session to a Google account.
  /// The anonymous user's data is preserved under the same uid.
  Future<bool> linkWithGoogle() async {
    final googleSignIn = _buildGoogleSignIn();

    final googleUser = await googleSignIn.signIn().onError((error, stackTrace) {
      debugPrint('AuthProvider.linkWithGoogle GoogleSignIn error: $error');
      throw _mapGoogleError(error ?? Exception('Unknown Google sign-in error'));
    });
    if (googleUser == null) {
      throw const AuthException('Google sign-in cancelled by user.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Google id token is null.');
    }

    return _client.auth.linkIdentity(
      OAuthProvider.google,
      // Pass tokens so Supabase can link without a redirect.
      queryParams: {
        'id_token': idToken,
        if (accessToken != null) 'access_token': accessToken,
      },
    );
  }

  // ─── Sign-Out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _buildGoogleSignIn().signOut();
    } catch (e) {
      debugPrint('AuthProvider: GoogleSignIn.signOut error: $e');
    }
    await _client.auth.signOut();
  }

  AuthException _mapGoogleError(Object error) {
    if (error is PlatformException &&
        error.code == 'sign_in_failed' &&
        '${error.message}'.contains('ApiException: 10')) {
      return const AuthException(
        'Google Sign-In is not configured correctly for this build. '
        'Add the app SHA certificate in Firebase, download a fresh '
        'google-services.json, and retry.',
      );
    }

    return AuthException(error.toString());
  }
}
