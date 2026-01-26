import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class PostController extends GetxController {
  var mediaList = <AssetEntity>[].obs;
  var selectedAsset = Rxn<AssetEntity>();

  var isFullImage = false.obs; // Observable to track toggle state

  void toggleFit() {
    isFullImage.value = !isFullImage.value;
  }

  @override
  void onInit() {
    super.onInit();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    // 1. Request Permission
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth || ps.hasAccess) {
      // 2. Filter for both Images and Videos
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // This includes Image + Video
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        // 3. Fetch more items (e.g., 100) to fill the grid
        List<AssetEntity> media = await albums[0].getAssetListPaged(page: 0, size: 100);
        mediaList.assignAll(media);

        if (media.isNotEmpty) {
          selectedAsset.value = media[0];
        }
      }
    } else {
      // If permission is denied, you can prompt the user to open settings
      // PhotoManager.openSetting();
    }
  }

  void selectMedia(AssetEntity asset) {
    selectedAsset.value = asset;
  }
}

/*
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class PostController extends GetxController {
  var mediaList = <AssetEntity>[].obs;
  var selectedAsset = Rxn<AssetEntity>();

  @override
  void onInit() {
    super.onInit();
    _fetchAssets();
  }

  _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true);
      if (albums.isNotEmpty) {
        List<AssetEntity> photos = await albums[0].getAssetListPaged(page: 0, size: 50);
        mediaList.assignAll(photos);
        if (photos.isNotEmpty) selectedAsset.value = photos[0];
      }
    }
  }

  void selectMedia(AssetEntity asset) {
    selectedAsset.value = asset;
  }
}*/
