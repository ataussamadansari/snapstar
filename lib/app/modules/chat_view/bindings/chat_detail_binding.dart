import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/chat_detail_controller.dart';

class ChatDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Handle both String (conversationId only) and Map arguments
    final dynamic args = Get.arguments;

    String conversationId;
    String username = 'User';

    if (args is String) {
      // Direct conversationId passed
      conversationId = args;
    } else if (args is Map<String, dynamic>) {
      // Map with conversationId and username
      conversationId = args['conversationId'] as String;
      username = args['username'] as String? ?? 'User';
    } else {
      throw Exception('Invalid arguments type for ChatDetailBinding');
    }

    Get.lazyPut<ChatDetailController>(
      () => ChatDetailController(
        Get.find<ChatRepository>(),
        Get.find<AuthRepository>(),
        Get.find<StorageService>(),
        conversationId,
        username,
      ),
    );
  }
}
