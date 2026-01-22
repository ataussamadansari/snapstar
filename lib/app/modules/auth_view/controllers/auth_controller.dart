import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/routes/app_routes.dart';

import '../../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository repository = AuthRepository();

  var isLoading = false.obs;
  var user = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
  }

  // --- SIGNUP LOGIC ---
  Future<void> register(String email, String password) async {
    try {
      isLoading.value = true;
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 1. Get Token
      String? token = await userCred.user?.getIdToken();

      if (token != null) {
        // 2. Sync with Node.js Backend
        // await _repository.syncUserWithBackend(token);
      }
    } catch (e) {
      Get.snackbar(
        "Signup Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- LOGIN LOGIC ---
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.offAllNamed(Routes.main);
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async => await _auth.signOut();
}
