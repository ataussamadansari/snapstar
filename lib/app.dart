import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/bindings/app_bindings.dart';
import 'app/core/themes/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: AppTheme.dark,
      theme: AppTheme.light,
      initialRoute: FirebaseAuth.instance.currentUser != null
      ? Routes.main : Routes.login,
      getPages: AppPages.routes,
      initialBinding: AppBindings(),
    );
  }
}
