import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../core/utils/helpers.dart';
import '../../../data/controllers/upload_task_controller.dart';
import '../../../modules/home_view/controllers/home_controller.dart';
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
  final UploadTaskController _uploadTaskController = Get.find();

  final ImagePicker _picker = ImagePicker();

  RxList<File> selectedFiles = <File>[].obs;
  Rx<File?> videoThumbnail = Rx<File?>(null);
  RxInt previewIndex = 0.obs;

  RxBool isVideo = false.obs;
  RxBool isLoading = false.obs;

  final captionCtrl = TextEditingController();

  Future<void> pickFromCamera() async {
    if (selectedFiles.length >= 5) {
      AppHelpers.showSnackBar(
        title: 'Limit reached',
        message: 'You can upload maximum 5 media files',
        isError: true,
      );
      return;
    }

    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image != null) {
      selectedFiles.add(File(image.path));
      previewIndex.value = 0;
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
      final remaining = 5 - selectedFiles.length;
      if (remaining <= 0) {
        AppHelpers.showSnackBar(
          title: 'Limit reached',
          message: 'You can upload maximum 5 media files',
          isError: true,
        );
        return;
      }

      final toAdd = images.take(remaining).map((e) => File(e.path)).toList();
      selectedFiles.addAll(toAdd);
      previewIndex.value = 0;

      if (images.length > remaining) {
        AppHelpers.showSnackBar(
          title: 'Limit reached',
          message: 'Only first 5 media files can be selected',
          isError: false,
        );
      }

      isVideo.value = false;
      videoThumbnail.value = null;
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final file = File(video.path);

      selectedFiles.value = [file];
      previewIndex.value = 0;
      isVideo.value = true;

      final thumb = await VideoCompress.getFileThumbnail(video.path);

      videoThumbnail.value = thumb;
    }
  }

  Future<void> createPost() async {
    if (selectedFiles.isEmpty) {
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Please select media first',
        isError: true,
      );
      return;
    }

    if (selectedFiles.length > 5) {
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Maximum 5 media files allowed per post',
        isError: true,
      );
      return;
    }

    if (isLoading.value) return;

    isLoading.value = true;

    final userId = _authRepo.currentUserId;
    if (userId == null) {
      isLoading.value = false;
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'User not authenticated',
        isError: true,
      );
      return;
    }

    final filesSnapshot = List<File>.from(selectedFiles);
    final thumbSnapshot = videoThumbnail.value;
    final captionSnapshot = captionCtrl.text.trim();
    final mediaTypeSnapshot = isVideo.value ? MediaType.video : MediaType.image;

    _resetFields();
    isLoading.value = false;

    _switchToHomeTab();

    AppHelpers.showSnackBar(
      title: 'Uploading',
      message: 'Post upload started in background',
      isError: false,
    );

    Future<void>.microtask(() async {
      final taskId = _uploadTaskController.start(
        type: UploadTaskType.post,
        label: 'Uploading post...',
      );

      try {
        final List<String> mediaUrls = [];
        final List<String> thumbUrls = [];
        final totalSteps = filesSnapshot.length + (thumbSnapshot != null ? 1 : 0) + 1;
        var completedSteps = 0;

        for (final file in filesSnapshot) {
          _uploadTaskController.updateTask(
            taskId,
            label: 'Uploading media...',
            progress: completedSteps / totalSteps,
          );

          final url = await repo.uploadMedia(
            file: file,
            userId: userId,
            type: mediaTypeSnapshot,
          );
          mediaUrls.add(url);
          completedSteps++;
          _uploadTaskController.updateTask(taskId, progress: completedSteps / totalSteps);
        }

        if (thumbSnapshot != null) {
          _uploadTaskController.updateTask(
            taskId,
            label: 'Uploading thumbnail...',
            progress: completedSteps / totalSteps,
          );
          final thumbUrl = await repo.uploadMedia(
            file: thumbSnapshot,
            userId: userId,
            type: MediaType.image,
          );
          thumbUrls.add(thumbUrl);
          completedSteps++;
          _uploadTaskController.updateTask(taskId, progress: completedSteps / totalSteps);
        }

        _uploadTaskController.updateTask(
          taskId,
          label: 'Publishing post...',
          progress: completedSteps / totalSteps,
        );

        final post = PostModel(
          id: '',
          userId: userId,
          mediaType: mediaTypeSnapshot,
          caption: captionSnapshot,
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
        _uploadTaskController.complete(taskId);

        if (Get.isRegistered<HomeController>()) {
          unawaited(Get.find<HomeController>().loadPosts(refresh: true));
        }
      } catch (e) {
        debugPrint('Create Post Background Error: $e');
        _uploadTaskController.fail(taskId, 'Post upload failed');
        AppHelpers.showSnackBar(
          title: 'Error',
          message: 'Post upload failed',
          isError: true,
        );
      }
    });
  }

  void _resetFields() {
    selectedFiles.clear();
    videoThumbnail.value = null;
    captionCtrl.clear();
    isVideo.value = false;
    previewIndex.value = 0;
  }

  void setPreviewIndex(int index) {
    previewIndex.value = index;
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= selectedFiles.length) return;
    selectedFiles.removeAt(index);
    if (selectedFiles.isEmpty) {
      previewIndex.value = 0;
      return;
    }
    if (previewIndex.value >= selectedFiles.length) {
      previewIndex.value = selectedFiles.length - 1;
    }
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
