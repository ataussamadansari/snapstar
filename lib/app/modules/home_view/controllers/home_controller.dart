import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class HomeController extends GetxController {

  void logOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.login);
  }

  final stories = List.generate(10, (index) => 'User $index');

  final posts = List.generate(
    10,
    (index) => {
      'username': 'user_$index',
      'caption': 'This is demo post caption $index',
      'likes': 10 + index,
    },
  );
}
