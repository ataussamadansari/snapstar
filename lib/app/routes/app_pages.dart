import 'package:get/get.dart';
import 'package:snapstar/app/modules/abc_view/bindings/abc_binding.dart';
import 'package:snapstar/app/modules/abc_view/views/abc_screen.dart';
import 'package:snapstar/app/modules/main_view/bindings/main_binding.dart';
import 'package:snapstar/app/modules/main_view/views/main_screen.dart';
import 'package:snapstar/app/modules/setup_profile_view/bindings/setup_profile_binding.dart';
import 'package:snapstar/app/modules/setup_profile_view/views/setup_profile_screen.dart';

import '../modules/login_view/bindings/login_binding.dart';
import '../modules/login_view/views/login_screen.dart';
import '../modules/register_view/bindings/register_binding.dart';
import '../modules/register_view/views/register_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.abc,
      page: () => AbcScreen(),
      binding: AbcBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.setupProfile,
      page: () => const SetupProfileScreen(),
      binding: SetupProfileBinding(),
    ),
    GetPage(
      name: Routes.main,
      page: () => const MainScreen(),
      binding: MainBinding(),
    ),
  ];
}
