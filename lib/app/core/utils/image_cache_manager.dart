import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Global image cache manager — CachedNetworkImage ke liye use karo.
///
/// Ye manager disk pe images 7 din tak store karta hai.
/// Isse Supabase Cached Egress drastically kam hoga kyunki
/// same image baar baar server se nahi aayegi.
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'appImageCacheKey';

  static final AppImageCacheManager instance = AppImageCacheManager._();

  AppImageCacheManager._()
      : super(
          Config(
            key,
            // 7 din tak disk pe rakho — user wahi posts baar baar dekhta hai
            stalePeriod: const Duration(days: 7),
            // Max 500 images disk pe — ~100-200 MB typically
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
