import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/data/services/storage_services.dart';
import '../../data/models/user/user_check.dart'; // Aapka banaya hua model

class GlobalUserController extends GetxController {
  final storage = StorageServices.to;
  static GlobalUserController get to => Get.find();

  // Rx variable for token
  RxString token = "".obs;
  final userData = Rxn<Data>();

  @override
  void onInit() async{
    super.onInit();
    await fetchAndSaveToken();
  }

  Future<void> fetchAndSaveToken() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 1. Token fetch karein (await zaroori hai)
        String? idToken = await currentUser.getIdToken();

        if (idToken != null) {
          // 2. Rx variable mein save karein
          token.value = idToken;

          // 3. Storage mein save karein (taaki app restart par mile)
          storage.setToken(idToken);

          debugPrint("✅ Token Saved Successfully: ${token.value}");
        }
      } else {
        debugPrint("⚠️ No Firebase user found");
      }
    } catch (e) {
      debugPrint("❌ Error fetching token: $e");
    }
  }

  // Data save karne ke liye function
  void updateUserData(Data? data) {
    userData.value = data;
  }

  // UI mein use karne ke liye getters
  String get username => userData.value?.username ?? "";
  String get profilePic => userData.value?.avatar ?? "";
}
