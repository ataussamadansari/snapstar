import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../controllers/subscriber_list_controller.dart';

class SubscriberListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriberListController>(
      () => SubscriberListController(
        Get.find<SubscriberRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
