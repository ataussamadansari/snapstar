import 'package:get/get.dart';

class HomeController extends GetxController {
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
