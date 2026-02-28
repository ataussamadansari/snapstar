import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_post_controller.dart';

class AddPostScreen extends GetView<AddPostController> {
  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "New Post",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
              : TextButton(
            onPressed: controller.createPost,
            child: Text(
              "Share",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Caption
            TextField(
              controller: controller.captionCtrl,
              maxLines: 4,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: "Write a caption...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.hintColor,
                ),
              ),
            ),

            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),

            /// Media Preview
            Obx(() => controller.selectedFiles.isEmpty
                ? _buildEmptyState(context)
                : _buildMediaPreview(context, controller)),

            const SizedBox(height: 30),

            /// Add Media Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showMediaPickerDialog(context),
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Media",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: theme.hintColor,
          ),
          const SizedBox(height: 8),
          Text(
            "No media selected",
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  /// Media Preview
  Widget _buildMediaPreview(
      BuildContext context, AddPostController controller) {

    final theme = Theme.of(context);

    if (controller.isVideo.value) {
      if (controller.videoThumbnail.value == null) {
        return const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                controller.videoThumbnail.value!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.play_circle_fill,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
                size: 64,
              ),
            ),
          ),
          _buildDeleteButton(context, () {
            controller.selectedFiles.clear();
            controller.videoThumbnail.value = null;
          }),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.selectedFiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  controller.selectedFiles[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildDeleteButton(
              context,
                  () => controller.selectedFiles.removeAt(index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteButton(
      BuildContext context, VoidCallback onTap) {

    final theme = Theme.of(context);

    return Positioned(
      right: 4,
      top: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            color: theme.colorScheme.onSurface,
            size: 14,
          ),
        ),
      ),
    );
  }

  /// Bottom Sheet
  void _showMediaPickerDialog(BuildContext context) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const Text(
              "Select Media",
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Get.back();
                controller.pickFromCamera();
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Photo"),
              onTap: () {
                Get.back();
                controller.pickImages();
              },
            ),

            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Video"),
              onTap: () {
                Get.back();
                controller.pickVideo();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}