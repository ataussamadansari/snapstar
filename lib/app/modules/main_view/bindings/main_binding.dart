import 'package:get/get.dart';

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
    // Get.lazyPut(() => AddPostController());
    // Get.lazyPut(() => ReelsController());
    // Get.lazyPut(() => ProfileController());
  }
}