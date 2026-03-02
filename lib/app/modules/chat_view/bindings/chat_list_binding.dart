import 'package:get/get.dart';

import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../controllers/chat_list_controller.dart';

class ChatListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatListController>(
      () => ChatListController(
        Get.find<ChatRepository>(),
        Get.find<SubscriberRepository>(),
      ),
    );
  }
}
