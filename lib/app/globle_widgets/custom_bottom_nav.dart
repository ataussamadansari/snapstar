import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/core/themes/app_colors.dart';

import '../modules/main_view/controllers/main_controller.dart';

class CustomBottomNav extends StatelessWidget {
  final MainController controller;

  const CustomBottomNav({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      // 👈 left, right, bottom = 10
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(40), // 👈 fully rounded
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
              _navItem(context, Icons.home, 0),
              _navItem(context, Icons.search, 1),
              _navItem(context, Icons.add, 2, isCenter: true),
              _navItem(context, Icons.movie_creation_rounded, 3),
              _navItem(context, Icons.person, 4),
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
        child: Icon(
          icon,
          size: isCenter ? 32 : 28,
          color: isCenter
              ? isSelected
                    ? context.theme.scaffoldBackgroundColor
                    : context.theme.primaryColor
              : isSelected
              ? context.theme.primaryColor
              : AppColors.gray600,

          shadows: isSelected ? [
            Shadow(
              // color: context.theme.primaryColor.withValues(alpha: 0.2),
              color: Colors.blue.shade200,
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ] : null,
        ),
      ),
    );
  }
}
