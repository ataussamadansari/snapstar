import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static final CustomCacheManager instance = CustomCacheManager();
}

class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'videoCacheKey';

  CustomCacheManager()
      : super(
          Config(
            key,
            // 7 din tak cache — video baar baar download nahi hogi
            stalePeriod: const Duration(days: 7),
            // Max 50 videos — zyada videos = zyada disk space
            maxNrOfCacheObjects: 50,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}