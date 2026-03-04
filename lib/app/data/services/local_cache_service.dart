import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalCacheService {
  static const Duration _defaultTtl = Duration(minutes: 2);

  Future<void> putJson(
    String key,
    Object value, {
    Duration ttl = _defaultTtl,
  }) async {
    try {
      final file = await _resolveFile(key);
      final payload = <String, dynamic>{
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
        'value': value,
      };
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (error, stackTrace) {
      debugPrint('LocalCacheService.putJson error: $error');
      debugPrint('LocalCacheService.putJson stack: $stackTrace');
    }
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final file = await _resolveFile(key);
      if (!await file.exists()) {
        return null;
      }

      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final savedAtRaw = decoded['saved_at']?.toString();
      final ttlMs = (decoded['ttl_ms'] as num?)?.toInt() ?? _defaultTtl.inMilliseconds;
      final savedAt = savedAtRaw == null ? null : DateTime.tryParse(savedAtRaw)?.toUtc();
      if (savedAt != null) {
        final expiresAt = savedAt.add(Duration(milliseconds: ttlMs));
        if (DateTime.now().toUtc().isAfter(expiresAt)) {
          try {
            await file.delete();
          } catch (_) {}
          return null;
        }
      }

      final value = decoded['value'];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is List) {
        return <String, dynamic>{'items': value};
      }
      return null;
    } catch (error, stackTrace) {
      debugPrint('LocalCacheService.getJson error: $error');
      debugPrint('LocalCacheService.getJson stack: $stackTrace');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      final file = await _resolveFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<File> _resolveFile(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/snapstar_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${cacheDir.path}/$sanitized.json');
  }
}
