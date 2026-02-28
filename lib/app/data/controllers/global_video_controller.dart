import 'package:get/get.dart';

class GlobalVideoController extends GetxController {

  /// 🔊 Global mute state
  final isMuted = true.obs;

  /// 🎥 Currently active playing video id
  final activeVideoId = RxnString();

  /// 🔁 Replay state
  final replayVideoId = RxnString();

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

  void triggerReplay(String id) {
    replayVideoId.value = id;
  }

  void clearReplay() {
    replayVideoId.value = null;
  }
}
