import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../main_view/controllers/main_controller.dart';
import '../controllers/post_controller.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PostScreen extends GetView<PostController> {
  const PostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Get.find<MainController>().changeTab(0)),
        title: const Text("New post", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Next", style: TextStyle(color: Colors.blue, fontSize: 18)))
        ],
      ),
      body: Column(
        children: [
          // 1. Preview Section
          // 1. Preview Section
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // The Image
                Obx(() => controller.selectedAsset.value == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black, // Background for "contain" mode
                  child: AssetEntityImage(
                    controller.selectedAsset.value!,
                    isOriginal: true,
                    // Switch between cover and contain
                    fit: controller.isFullImage.value ? BoxFit.contain : BoxFit.cover,
                  ),
                )),

                // The Toggle Button (Bottom Left)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () => controller.toggleFit(),
                    child: Obx(() => CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      radius: 18,
                      child: Icon(
                        controller.isFullImage.value
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),

          /*Expanded(
            flex: 4,
            child: Obx(() => controller.selectedAsset.value == null
                ? const Center(child: CircularProgressIndicator())
                : AssetEntityImage(controller.selectedAsset.value!, isOriginal: true, fit: BoxFit.cover, width: double.infinity)),
          ),*/

          // 2. Gallery Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Text("Recents", style: TextStyle(fontWeight: FontWeight.bold)), Icon(Icons.expand_more)]),
                CircleAvatar(backgroundColor: Colors.grey[800], child: const Icon(Icons.copy, size: 18, color: Colors.white)),
              ],
            ),
          ),

          // 3. Grid Selection
          Expanded(
            flex: 5,
            child: Obx(() => GridView.builder(
              padding: EdgeInsets.only(bottom: 85, left: 1, right: 1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemCount: controller.mediaList.length,
              itemBuilder: (context, index) {
                AssetEntity asset = controller.mediaList[index];
                return GestureDetector(
                  onTap: () => controller.selectMedia(asset),
                  child: AssetEntityImage(asset, isOriginal: false, thumbnailSize: const ThumbnailSize.square(200), fit: BoxFit.cover),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}
