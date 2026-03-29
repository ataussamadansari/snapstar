import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';

import '../data/controllers/story_controller.dart';
import '../data/controllers/post_story_style_controller.dart';
import '../data/models/story_model.dart';
import 'app_avatar.dart';

class StoryCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isYourStory;
  final bool hasStory;
  final bool hasUnseen;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.isYourStory = false,
    this.hasStory = true,
    this.hasUnseen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styleController = Get.find<PostStoryStyleController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showStoryRing = hasUnseen || (isYourStory && hasStory);

    return Obx(() {
      final selectedLabelColor = styleController.storyLabelColor;
      final textColor =
          selectedLabelColor.toARGB32() == Colors.transparent.toARGB32()
          ? (isDark ? Colors.white : Colors.black)
          : selectedLabelColor;
      final cardWidth = styleController.storyCardWidth.value;
      final avatarRadius = styleController.storyAvatarRadius.value;
      final ringStartColor = styleController.storyRingStartColor;
      final ringEndColor = styleController.storyRingEndColor;

      return GestureDetector(
        onTap: () {
          if (isYourStory) {
            if (!hasStory) {
              _showStoryOptions(context);
            } else {
              onTap?.call();
            }
          } else {
            onTap?.call();
          }
        },
        child: SizedBox(
          width: cardWidth,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: showStoryRing
                          ? LinearGradient(
                              colors: [ringStartColor, ringEndColor],
                            )
                          : null,
                    ),
                    child: AppAvatar(
                      radius: avatarRadius,
                      avatarUrl: imageUrl,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      iconColor: isDark ? Colors.white : Colors.black54,
                    ),
                  ),

                  if (isYourStory)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          _showStoryOptions(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white : Colors.black,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.add,
                            size: (avatarRadius * 0.45).clamp(12, 18),
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                isYourStory ? "Your Story" : name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ================= BOTTOM SHEET =================

  void _showStoryOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create Story",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              _optionTile(
                context,
                icon: Icons.camera_alt,
                title: "Camera",
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? file = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (file != null) {
                    _handleStoryFile(file, isVideo: false);
                  }
                },
              ),

              _optionTile(
                context,
                icon: Icons.photo,
                title: "Images",
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (file != null) {
                    _handleStoryFile(file, isVideo: false);
                  }
                },
              ),

              _optionTile(
                context,
                icon: Icons.videocam,
                title: "Videos",
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? file = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );

                  if (file != null) {
                    _handleStoryFile(file, isVideo: true);
                  }
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _handleStoryFile(XFile file, {required bool isVideo}) async {
    final storyController = Get.find<StoryController>();

    await storyController.uploadStory(
      userId: AuthHelper.currentUserId,
      file: File(file.path),
      mediaType: isVideo ? StoryMediaType.video : StoryMediaType.image,
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        child: Icon(icon, color: isDark ? Colors.white : Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      onTap: onTap,
    );
  }
}
