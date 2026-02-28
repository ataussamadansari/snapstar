import 'package:get/get.dart';

class GlobalMediaController extends GetxController {

  /// 🔊 Global mute
  final isMuted = true.obs;

  /// 🎥 Active video id
  final activeVideoId = RxnString();

  /// ❤️ Double tap post id
  final doubleTapPostId = RxnString();

  void toggleMute() {
    isMuted.value = !isMuted.value;
  }

  void setActiveVideo(String id) {
    activeVideoId.value = id;
  }

  void clearActiveVideo(String id) {
    if (activeVideoId.value == id) {
      activeVideoId.value = null;
    }
  }

  void triggerDoubleTap(String postId) {
    doubleTapPostId.value = postId;

    Future.delayed(const Duration(milliseconds: 600), () {
      doubleTapPostId.value = null;
    });
  }
}
