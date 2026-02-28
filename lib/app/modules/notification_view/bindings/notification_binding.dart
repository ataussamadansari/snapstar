import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../controllers/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationController>(
      () => NotificationController(
        Get.find<NotificationRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
