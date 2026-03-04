import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/local_cache_service.dart';

class PostStoryStyleController extends GetxController {
  PostStoryStyleController(this._cacheService);

  final LocalCacheService _cacheService;
  static const _cacheKey = 'ui_post_story_style_v1';

  final postCornerRadius = 0.0.obs;
  final postActionIconSize = 28.0.obs;
  final postBackgroundColorValue = Colors.transparent.toARGB32().obs;

  final storyCardWidth = 85.0.obs;
  final storyAvatarRadius = 35.0.obs;
  final storyLabelColorValue = Colors.transparent.toARGB32().obs;
  final storyRingStartColorValue = Colors.pink.toARGB32().obs;
  final storyRingEndColorValue = Colors.orange.toARGB32().obs;

  Color get postBackgroundColor => Color(postBackgroundColorValue.value);
  Color get storyLabelColor => Color(storyLabelColorValue.value);
  Color get storyRingStartColor => Color(storyRingStartColorValue.value);
  Color get storyRingEndColor => Color(storyRingEndColorValue.value);

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
  }

  Future<void> setPostCornerRadius(double value) async {
    postCornerRadius.value = value.clamp(0, 24);
    await _saveToCache();
  }

  Future<void> setPostActionIconSize(double value) async {
    postActionIconSize.value = value.clamp(22, 34);
    await _saveToCache();
  }

  Future<void> setPostBackgroundColor(Color color) async {
    postBackgroundColorValue.value = color.toARGB32();
    await _saveToCache();
  }

  Future<void> setStoryCardWidth(double value) async {
    storyCardWidth.value = value.clamp(72, 110);
    await _saveToCache();
  }

  Future<void> setStoryAvatarRadius(double value) async {
    storyAvatarRadius.value = value.clamp(28, 44);
    await _saveToCache();
  }

  Future<void> setStoryLabelColor(Color color) async {
    storyLabelColorValue.value = color.toARGB32();
    await _saveToCache();
  }

  Future<void> setStoryRingStartColor(Color color) async {
    storyRingStartColorValue.value = color.toARGB32();
    await _saveToCache();
  }

  Future<void> setStoryRingEndColor(Color color) async {
    storyRingEndColorValue.value = color.toARGB32();
    await _saveToCache();
  }

  Future<void> resetDefaults() async {
    postCornerRadius.value = 0;
    postActionIconSize.value = 28;
    postBackgroundColorValue.value = Colors.transparent.toARGB32();
    storyCardWidth.value = 85;
    storyAvatarRadius.value = 35;
    storyLabelColorValue.value = Colors.transparent.toARGB32();
    storyRingStartColorValue.value = Colors.pink.toARGB32();
    storyRingEndColorValue.value = Colors.orange.toARGB32();
    await _saveToCache();
  }

  Future<void> _loadFromCache() async {
    final cached = await _cacheService.getJson(_cacheKey);
    if (cached == null || cached.isEmpty) {
      return;
    }

    postCornerRadius.value = _readDouble(cached['postCornerRadius'], 0);
    postActionIconSize.value = _readDouble(cached['postActionIconSize'], 28);
    postBackgroundColorValue.value = _readInt(
      cached['postBackgroundColorValue'],
      Colors.transparent.toARGB32(),
    );
    storyCardWidth.value = _readDouble(cached['storyCardWidth'], 85);
    storyAvatarRadius.value = _readDouble(cached['storyAvatarRadius'], 35);
    storyLabelColorValue.value = _readInt(
      cached['storyLabelColorValue'],
      Colors.transparent.toARGB32(),
    );
    storyRingStartColorValue.value = _readInt(
      cached['storyRingStartColorValue'],
      Colors.pink.toARGB32(),
    );
    storyRingEndColorValue.value = _readInt(
      cached['storyRingEndColorValue'],
      Colors.orange.toARGB32(),
    );
  }

  Future<void> _saveToCache() {
    return _cacheService.putJson(_cacheKey, {
      'postCornerRadius': postCornerRadius.value,
      'postActionIconSize': postActionIconSize.value,
      'postBackgroundColorValue': postBackgroundColorValue.value,
      'storyCardWidth': storyCardWidth.value,
      'storyAvatarRadius': storyAvatarRadius.value,
      'storyLabelColorValue': storyLabelColorValue.value,
      'storyRingStartColorValue': storyRingStartColorValue.value,
      'storyRingEndColorValue': storyRingEndColorValue.value,
    }, ttl: const Duration(days: 3650));
  }

  double _readDouble(Object? value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  int _readInt(Object? value, int fallback) {
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }
}
