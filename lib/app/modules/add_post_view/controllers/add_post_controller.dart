import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../main_view/controllers/main_controller.dart';

class AddPostController extends GetxController {
  AddPostController(
    this.repo,
    this._authRepo,
  );

  final PostRepository repo;
  final AuthRepository _authRepo;

  final ImagePicker _picker = ImagePicker();

  RxList<File> selectedFiles = <File>[].obs;
  Rx<File?> videoThumbnail = Rx<File?>(null);

  RxBool isVideo = false.obs;
  RxBool isLoading = false.obs;

  final captionCtrl = TextEditingController();

  Future<void> pickFromCamera() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image != null) {
      selectedFiles.value = [File(image.path)];
      isVideo.value = false;
      videoThumbnail.value = null;
    }
  }

  Future<void> pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 75,
      maxWidth: 1080,
    );

    if (images.isNotEmpty) {
      selectedFiles.value = images.take(5).map((e) => File(e.path)).toList();

      isVideo.value = false;
      videoThumbnail.value = null;
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final file = File(video.path);

      selectedFiles.value = [file];
      isVideo.value = true;

      final thumb = await VideoCompress.getFileThumbnail(video.path);

      videoThumbnail.value = thumb;
    }
  }

  Future<void> createPost() async {
    if (selectedFiles.isEmpty) {
      Get.snackbar('Error', 'Please select media first');
      return;
    }

    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final userId = _authRepo.currentUserId;
      if (userId == null) {
        throw StateError('User not authenticated');
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
        mediaType: isVideo.value ? MediaType.video : MediaType.image,
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

      final didSwitchToHome = _switchToHomeTab();
      if (!didSwitchToHome && (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }

      Get.snackbar(
        'Success',
        'Post uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Create Post Error: $e');

      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _resetFields() {
    selectedFiles.clear();
    videoThumbnail.value = null;
    captionCtrl.clear();
    isVideo.value = false;
  }

  bool _switchToHomeTab() {
    if (!Get.isRegistered<MainController>()) {
      return false;
    }

    Get.find<MainController>().changeIndex(0);
    return true;
  }

  @override
  void onClose() {
    captionCtrl.dispose();
    VideoCompress.dispose();
    super.onClose();
  }
}
