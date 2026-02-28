import 'package:get/get.dart';

import '../../reels_view/controllers/reels_controller.dart';

class MainController extends GetxController {
  // Current active index
  var currentIndex = 0.obs;

  // Change index method
  void changeIndex(int index, {bool preserveReelsContext = false}) {
    if (index == 3 &&
        !preserveReelsContext &&
        Get.isRegistered<ReelsController>()) {
      Get.find<ReelsController>().switchToGlobalFeedIfNeeded();
    }

    currentIndex.value = index;
  }
}
