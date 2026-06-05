import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/modules/add_post_view/views/add_post_screen.dart';
import 'package:snapstar_app/app/modules/home_view/views/home_screen.dart';
import 'package:snapstar_app/app/modules/profile_view/views/profile_screen.dart';
import 'package:snapstar_app/app/modules/reels_view/views/reels_screen.dart';
import 'package:snapstar_app/app/modules/search_view/views/search_screen.dart';
import '../controllers/main_controller.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Default pop behavior ko disable karein
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Agar index 0 (Home) nahi hai, toh index 0 par bhej do
        if (controller.currentIndex.value != 0) {
          controller.changeIndex(0);
        } else {
          // Agar pehle se Home par hai, toh app close kar do
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Obx(() => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            HomeScreen(),
            SearchScreen(),
            AddPostScreen(),
            ReelsScreen(),
            ProfileScreen(),
          ],
        )),
      
        bottomNavigationBar: Obx(
              () => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            backgroundColor: Theme.of(context).colorScheme.surface,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: "Add"),
              BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: "Reels"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}
