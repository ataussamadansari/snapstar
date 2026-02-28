import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_post_controller.dart';

class AddPostScreen extends GetView<AddPostController> {
  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: const Text("New Post", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: controller.createPost,
            child: const Text(
              "Share",
              style: TextStyle(
                color: Colors.blue,
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
            /// 1. Caption Section
            TextField(
              controller: controller.captionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Write a caption...",
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),

            /// 3. Media Preview (Optimized)
            Obx(() => controller.selectedFiles.isEmpty
                ? _buildEmptyState()
                : _buildMediaPreview(controller)),

            const SizedBox(height: 30),

            /// 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                    onPressed: controller.pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Photos"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                    onPressed: controller.pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Video"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State Placeholder
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text("No media selected", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  /// Media Preview Logic
  Widget _buildMediaPreview(AddPostController controller) {
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
              child: Image.file(controller.videoThumbnail.value!, fit: BoxFit.cover),
            ),
          ),
          const Positioned.fill(
            child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64)),
          ),
          _buildDeleteButton(() {
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
                child: Image.file(controller.selectedFiles[index], fit: BoxFit.cover),
              ),
            ),
            _buildDeleteButton(() => controller.selectedFiles.removeAt(index)),
            if (index == 0 && controller.selectedFiles.length > 1)
              const Positioned(
                bottom: 4,
                left: 4,
                child: Icon(Icons.collections, color: Colors.white, size: 18),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteButton(VoidCallback onTap) {
    return Positioned(
      right: 4,
      top: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}