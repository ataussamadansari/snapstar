import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/modules/home_view/views/home_screen.dart';
import 'package:snapstar/app/modules/search_view/views/search_screen.dart';
import '../../../globle_widgets/custom_bottom_nav.dart';
import '../controllers/main_controller.dart';
import '../../post_view/views/post_screen.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      SearchScreen(),
      PostScreen(),
      Center(child: Text("Reels")),
      Center(child: Text("Profile")),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if(didPop) result;

        if(controller.selectedIndex.value != 0) {
          controller.changeTab(0);
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            /// 🔥 FULL SCREEN CONTENT
            Obx(
                  () => IndexedStack(
                index: controller.selectedIndex.value,
                children: pages,
              ),
            ),

            /// 👇 OVERLAY CUSTOM BOTTOM NAV
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNav(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/modules/home_view/views/home_screen.dart';
import 'package:snapstar/app/modules/search_view/views/search_screen.dart';
import '../../../globle_widgets/custom_bottom_nav.dart';
import '../controllers/main_controller.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      SearchScreen(),
      Center(child: Text("Add Post")),
      Center(child: Text("Reels")),
      Center(child: Text("Profile")),
    ];

    return Scaffold(
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
      ),

      // 👇 CUSTOM BOTTOM NAV
      bottomNavigationBar: CustomBottomNav(controller: controller),
    );
  }
}
*/
