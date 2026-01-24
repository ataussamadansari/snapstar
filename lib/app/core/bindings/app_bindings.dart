import 'package:get/get.dart';

import '../../data/providers/api_provider.dart';
import '../../data/services/api_services.dart';
import '../../data/services/storage_services.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StorageServices>(() => StorageServices(), fenix: true);

    // Initialize ApiProvider
    Get.put(ApiProvider(), permanent: true);

    // Initialize ApiServices
    Get.put(ApiServices(), permanent: true);
  }
}
