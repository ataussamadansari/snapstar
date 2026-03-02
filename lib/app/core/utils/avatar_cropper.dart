import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';

class AvatarCropper {
  static Future<File?> cropSquare(String sourcePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust profile photo',
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Adjust profile photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null) {
        return null;
      }

      return File(cropped.path);
    } on MissingPluginException catch (error) {
      debugPrint('AvatarCropper plugin missing, using original image: $error');
      return File(sourcePath);
    } on PlatformException catch (error) {
      debugPrint('AvatarCropper platform error, using original image: $error');
      return File(sourcePath);
    }
  }
}
