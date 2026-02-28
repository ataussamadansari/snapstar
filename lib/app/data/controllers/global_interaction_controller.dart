import 'package:get/get.dart';

class GlobalInteractionController extends GetxController {

  final doubleTapPostId = RxnString();

  void triggerDoubleTap(String postId) {
    doubleTapPostId.value = postId;

    Future.delayed(const Duration(milliseconds: 600), () {
      doubleTapPostId.value = null;
    });
  }
}
