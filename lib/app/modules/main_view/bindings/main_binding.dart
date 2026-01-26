import 'package:get/get.dart';
import 'package:snapstar/app/modules/post_view/bindings/post_binding.dart';
import 'package:snapstar/app/modules/post_view/controllers/post_controller.dart';

import '../../home_view/controllers/home_controller.dart';
import '../../search_view/controllers/search_controller.dart';
import '../controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());

    // pages
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => SearchController());
    Get.lazyPut(() => PostController());
    // Get.lazyPut(() => ReelsController());
    // Get.lazyPut(() => ProfileController());
  }
}