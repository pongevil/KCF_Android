import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/core/barcode/barcode_config_validator.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_model.dart';
import 'package:bs_mobile/src/core/barcode/barcode_format_repository.dart';
import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:path_provider/path_provider.dart';

/// Memory TTL + persistent last-known-good cache for barcode formats.
///
/// API returns flat `fields` grouped by `tag_function` in the repository.
class BarcodeFormatService {
  BarcodeFormatService(this._repository, {Duration? ttl})
    : _ttl = ttl ?? const Duration(hours: 12);

  final BarcodeFormatRepository _repository;
  final Duration _ttl;

  Map<String, BarcodeFormatConfig> _byTagFunction = {};
  DateTime? _bundleCachedAt;
  Future<Map<String, BarcodeFormatConfig>>? _inflight;

  /// Optional override for unit tests (bypass path_provider).
  Directory? debugCacheDirectory;

  /// Lookup one layout by exact [tagFunction]. Loads get-all bundle if needed.
  Future<BarcodeFormatConfig?> getFormat(String tagFunction) async {
    final key = tagFunction.trim();
    if (key.isEmpty) return null;

    await _ensureBundleLoaded();
    return _byTagFunction[key];
  }

  /// Login / refresh — fetch all formats once into memory + disk LKG.
  Future<void> prefetchAll() async {
    await _ensureBundleLoaded(forceRefresh: true);
  }

  void clearMemory() {
    _byTagFunction = {};
    _bundleCachedAt = null;
  }

  Future<void> _ensureBundleLoaded({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _bundleCachedAt != null &&
        !_isExpired(_bundleCachedAt!) &&
        _byTagFunction.isNotEmpty) {
      return;
    }

    final existing = _inflight;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _loadAll();
    _inflight = future;
    try {
      await future;
    } finally {
      _inflight = null;
    }
  }

  Future<Map<String, BarcodeFormatConfig>> _loadAll() async {
    try {
      final remote = await _repository.fetchAll();
      final map = <String, BarcodeFormatConfig>{};
      for (final config in remote) {
        final key = config.tagFunction.trim();
        if (key.isEmpty) continue;
        map[key] = config;
      }

      if (map.isEmpty) {
        printDebug(
          'BarcodeFormat get-all empty after validate — keep LKG',
          DebugLogType.error,
        );
        await _restoreStaleBundle();
        return _byTagFunction;
      }

      _byTagFunction = map;
      _bundleCachedAt = DateTime.now();
      await _writeDiskBundle(map.values.toList());
      return map;
    } catch (e) {
      printDebug('BarcodeFormat get-all failed: $e', DebugLogType.error);
      await _restoreStaleBundle();
      return _byTagFunction;
    }
  }

  Future<void> _restoreStaleBundle() async {
    if (_byTagFunction.isNotEmpty) {
      printDebug(
        'BarcodeFormat using stale memory LKG bundle',
        DebugLogType.debug,
      );
      return;
    }

    final disk = await _readDiskBundle();
    if (disk.isEmpty) return;

    printDebug(
      'BarcodeFormat using stale disk LKG bundle (${disk.length} formats)',
      DebugLogType.debug,
    );
    _byTagFunction = {
      for (final config in disk) config.tagFunction.trim(): config,
    };
    _bundleCachedAt = disk.first.fetchedAt ?? DateTime.now();
  }

  bool _isExpired(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) >= _ttl;
  }

  Future<Directory> _cacheDir() async {
    if (debugCacheDirectory != null) {
      final dir = debugCacheDirectory!;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/barcode_format');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _bundleFile() async {
    final dir = await _cacheDir();
    return File('${dir.path}/all.json');
  }

  Future<void> _writeDiskBundle(List<BarcodeFormatConfig> configs) async {
    try {
      final file = await _bundleFile();
      final payload = {
        'fetched_at': DateTime.now().toIso8601String(),
        'message_code': '0',
        'is_success': true,
        'items': configs.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      printDebug('BarcodeFormat disk write failed: $e', DebugLogType.error);
    }
  }

  Future<List<BarcodeFormatConfig>> _readDiskBundle() async {
    try {
      final file = await _bundleFile();
      if (!await file.exists()) return const [];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];

      final list = BarcodeFormatListResponse.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final valid = <BarcodeFormatConfig>[];
      for (final item in list.items) {
        final validation = BarcodeConfigValidator.validate(item);
        if (!validation.isValid) {
          printDebug(
            'BarcodeFormat disk LKG skip ${item.tagFunction}: '
            '${validation.errorCode}',
            DebugLogType.error,
          );
          continue;
        }
        valid.add(item);
      }
      return valid;
    } catch (e) {
      printDebug('BarcodeFormat disk read failed: $e', DebugLogType.error);
      return const [];
    }
  }
}
