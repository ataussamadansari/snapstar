import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';

import '../../reels_view/controllers/reels_controller.dart';

class MainController extends GetxController {
  // Current active index
  var currentIndex = 0.obs;

  // Change index method
  void changeIndex(int index, {bool preserveReelsContext = false}) {
    // Requirement 5: Route Protection for Tabs
    if (index == 2) { // Add Post Tab
      if (!AuthHelper.checkAuthAndShowModal(message: "Login with Google to share your moments!")) {
        return;
      }
    }
    
    if (index == 4) { // Profile Tab
       // Usually we allow viewing profile, but maybe restrict if they want to see "My Posts" which don't exist
       // Requirement 5 mentions "Profile edit" as restricted. 
       // If the Profile tab is purely for the current user, we might want to prompt login.
       if (!AuthHelper.checkAuthAndShowModal(message: "Login to see your profile and posts")) {
        return;
      }
    }

    if (index == 3 &&
        !preserveReelsContext &&
        Get.isRegistered<ReelsController>()) {
      Get.find<ReelsController>().switchToGlobalFeedIfNeeded();
    }

    currentIndex.value = index;
  }
}
