import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar_app/app/modules/main_view/controllers/main_controller.dart';
import 'package:video_compress/video_compress.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';

class AddPostController extends GetxController {
  PostRepository get repo => Get.find<PostRepository>();
  AuthRepository get _authRepo => Get.find<AuthRepository>();

  RxList<File> selectedFiles = <File>[].obs;
  Rx<File?> videoThumbnail = Rx<File?>(null);

  RxBool isVideo = false.obs;
  RxBool isLoading = false.obs;


  final captionCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  /// 🔹 Pick Images
  Future<void> pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1080,
    );

    if (images.isNotEmpty) {
      selectedFiles.value =
          images.take(5).map((e) => File(e.path)).toList();
      isVideo.value = false;
      videoThumbnail.value = null;
    }
  }

  /// 🔹 Pick Video + Thumbnail
  Future<void> pickVideo() async {
    final XFile? video =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final file = File(video.path);
      selectedFiles.value = [file];
      isVideo.value = true;

      final thumb =
      await VideoCompress.getFileThumbnail(video.path);
      videoThumbnail.value = thumb;
    }
  }

  /// 🔹 CREATE POST
  Future<void> createPost() async {
    if (selectedFiles.isEmpty) return;

    isLoading.value = true;

    try {
      final userId = _authRepo.currentUserId;
      if (userId == null) {
        throw StateError("User not authenticated");
      }

      final List<String> mediaUrls = [];
      final List<String> thumbUrls = [];

      for (final file in selectedFiles) {
        final url = await repo.uploadMedia(
          file: file,
          userId: userId,
          type: isVideo.value ? MediaType.video : MediaType.image,
        );

        mediaUrls.add(url);
      }

      if (isVideo.value && videoThumbnail.value != null) {
        final thumbUrl = await repo.uploadMedia(
          file: videoThumbnail.value!,
          userId: userId,
          type: MediaType.image,
        );

        thumbUrls.add(thumbUrl);
      }

      final post = PostModel(
        id: '',
        userId: userId,
        mediaType:
        isVideo.value ? MediaType.video : MediaType.image,
        caption: captionCtrl.text.trim(),
        mediaUrls: mediaUrls,
        thumbnailUrls: thumbUrls,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isDeleted: false,
        location: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createPost(post);

      _resetFields();

    } catch (e) {
      debugPrint("Create Post Error: $e");
    } finally {
      isLoading.value = false;
    }
  }


  // 🟢 Helper function fields reset karne ke liye
  void _resetFields() {
    selectedFiles.clear();
    videoThumbnail.value = null;
    captionCtrl.clear();
    isVideo.value = false;
  }

  @override
  void onClose() {
    captionCtrl.dispose();
    VideoCompress.dispose();
    super.onClose();
  }
}
