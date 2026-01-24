import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageServices extends GetxService
{
  static StorageServices get to => Get.find();
  GetStorage _box = GetStorage();

  // ✅ Reactive variables
  RxString userId = "".obs;
  RxString token = "".obs;

  @override
  void onInit() async
  {
    super.onInit();
    await GetStorage.init();
    _box = GetStorage();

    // Initialize reactive variables from storage
    userId.value = _box.read("userId") ?? "";
    token.value = _box.read("token") ?? "";
  }

  // Token Management
  String? getToken() => _box.read('token');
  void setToken(String t)
  {
    _box.write('token', t);
    token.value = t; // reactive update
  }

  void removeToken()
  {
    _box.remove('token');
    token.value = "";
  }

  // User ID Management
  String? getUserId() => _box.read('userId');
  void setUserId(String id)
  {
    _box.write('userId', id);
    userId.value = id; // reactive update
  }

  void removeUserId()
  {
    _box.remove('userId');
    userId.value = ""; // reactive update
  }

  // Language Management
  String? getLanguage() => _box.read('language');
  void setLanguage(String language) => _box.write('language', language);

  // Theme Management
  bool isDarkMode() => _box.read('darkMode') ?? false;
  void setDarkMode(bool value) => _box.write('darkMode', value);

  // Generic Storage Methods
  T? read<T>(String key) => _box.read(key);
  void write<T>(String key, T value) => _box.write(key, value);
  void remove<T>(String key) => _box.remove(key);
  void clear()
  {
    _box.erase();
    userId.value = "";
    token.value = "";
  }
}
