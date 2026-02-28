import 'package:get/get.dart';

import '../controllers/story_viewer_controller.dart';

class StoryViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoryViewerController>(() => StoryViewerController());
  }

}