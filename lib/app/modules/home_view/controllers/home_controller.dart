import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {


  @override
  void onInit() async {
    super.onInit();
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    debugPrint("Token: $token");
  }


  final stories = List.generate(
    10,
        (index) => 'User $index',
  );

  final posts = List.generate(
    10,
        (index) => {
      'username': 'user_$index',
      'caption': 'This is demo post caption $index',
      'likes': 10 + index,
    },
  );
}
