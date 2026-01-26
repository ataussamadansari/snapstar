import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/core/themes/app_colors.dart';

import '../core/utils/global_user_controller.dart';
import '../modules/main_view/controllers/main_controller.dart';

class CustomBottomNav extends StatelessWidget {
  final MainController controller;

  const CustomBottomNav({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: context.theme.primaryColor.withValues(alpha: 0.1),
              spreadRadius: 5,
              blurRadius: 10,
            ),
          ],
        ),
        child: Obx(
              () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home_filled, 0),
              _navItem(context, Icons.search, 1),
              _navItem(context, Icons.add, 2, isCenter: true),
              _navItem(context, Icons.movie_creation_rounded, 3),
              // Profile Tab (Index 4)
              _navItem(context, Icons.person, 4, isProfile: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context,
      IconData icon,
      int index, {
        bool isCenter = false,
        bool isProfile = false,
      }) {
    final isSelected = controller.selectedIndex.value == index;

    return Expanded( // 👈 1. Expanded lagaya taaki full available area cover kare
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 👈 2. Ye poore area par click allow karega
        onTap: () => controller.changeTab(index),
        child: Container(
          // Transparent color dena zaroori hai hit detection ke liye
          color: Colors.transparent,
          child: Center( // 👈 3. Center mein rakha taaki icon beech mein rahe
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: isCenter
                  ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: context.theme.primaryColor.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
                color: isSelected
                    ? context.theme.primaryColor
                    : context.theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              )
                  : null,
              child: isProfile
                  ? _buildProfileIcon(context, isSelected)
                  : Icon(
                icon,
                size: isCenter ? 32 : 28,
                color: isCenter
                    ? (isSelected ? context.theme.scaffoldBackgroundColor : context.theme.primaryColor)
                    : (isSelected ? context.theme.primaryColor : AppColors.gray600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*Widget _navItem(
      BuildContext context,
      IconData icon,
      int index, {
        bool isCenter = false,
        bool isProfile = false,
      }) {
    final isSelected = controller.selectedIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: isCenter
            ? BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: context.theme.primaryColor.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
          color: isSelected
              ? context.theme.primaryColor
              : context.theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        )
            : null,
        child: isProfile
            ? _buildProfileIcon(context, isSelected) // 👈 Agar profile hai toh image dikhao
            : Icon(
          icon,
          size: isCenter ? 32 : 28,
          color: isCenter
              ? isSelected
              ? context.theme.scaffoldBackgroundColor
              : context.theme.primaryColor
              : isSelected
              ? context.theme.primaryColor
              : AppColors.gray600,
        ),
      ),
    );
  }*/

  // Profile Picture Widget
  Widget _buildProfileIcon(BuildContext context, bool isSelected) {
    // GlobalUserController ko find karein
    final userController = Get.find<GlobalUserController>();

    return Obx(() {
      final avatarUrl = userController.profilePic;

      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? context.theme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: 14, // Size adjust kiya icons ke hisaab se
          backgroundColor: AppColors.gray200,
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : const AssetImage('assets/images/default_user.png') as ImageProvider,
        ),
      );
    });
  }
}