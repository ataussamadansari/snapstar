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
      stalePeriod: const Duration(days: 7), // 7 din tak cache rahega
      maxNrOfCacheObjects: 100, // Max 100 videos save hongi
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}