import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sookshicha_dhukkikenda/core/constants/app_constants.dart';
import 'package:sookshicha_dhukkikenda/core/error/exceptions.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';

/// Abstract class for local storage operations using Hive
abstract class LocalStorageService {
  /// Initialize Hive
  Future<void> init();

  /// Open a box
  Future<Box<T>> openBox<T>(String boxName);

  /// Get a value from a box
  T? getValue<T>(String boxName, String key);

  /// Get all values from a box
  List<T> getAllValues<T>(String boxName);

  /// save a value to a box
  Future<void> saveValue<T>(String boxName, String key, T value);

  /// Save multiple values to a box
  Future<void> saveAllValues<T>(String boxName, Map<String, T> entries);

  /// Delete a value from a box
  Future<void> deleteValue(String boxName, String key);

  /// Delete all values from a box
  Future<void> clearBox(String boxName);

  /// Check if a key exists in a box
  bool containsKey(String boxName, String key);

  /// Close a box
  Future<void> closeBox(String boxName);

  /// Close all boxes
  Future<void> closeAllBoxes();

  /// Delete a box from disk
  Future<void> deleteBox(String boxName);

  /// Watch for changes in a box
  Stream<BoxEvent> watchBox(String boxName, {String? key});
}

/// Implementation of LocalStorageService using Hive
@LazySingleton(as: LocalStorageService)
class LocalStorageServiceImpl implements LocalStorageService {
  final Map<String, Box<dynamic>> _boxes = {};

  @override
  Future<void> init() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);
      AppLogger.i('Hive initialized at: ${appDocDir.path}');
    } catch (e) {
      AppLogger.e('Failed to initialize Hive', e);
      throw CacheException(message: 'Failed to initialize local storage: $e');
    }
  }

  @override
  Future<Box<T>> openBox<T>(String boxName) async {
    try {
      if (_boxes.containsKey(boxName)) {
        return _boxes[boxName] as Box<T>;
      }

      final box = await Hive.openBox<T>(boxName);
      _boxes[boxName] = box;
      AppLogger.d('Opened box: $boxName');
      return box;
    } catch (e) {
      AppLogger.e('Failed to open box: $boxName', e);
      throw CacheException(message: 'Failed to open storage box: $e');
    }
  }

  Box<T>? _getBox<T>(String boxName) {
    if (!_boxes.containsKey(boxName)) {
      AppLogger.w('Box not opened: $boxName');
      return null;
    }
    return _boxes[boxName] as Box<T>?;
  }

  @override
  T? getValue<T>(String boxName, String key) {
    try {
      final box = _getBox<T>(boxName);
      return box?.get(key);
    } catch (e) {
      AppLogger.e('Failed to get value: $key from $boxName', e);
      return null;
    }
  }

  @override
  List<T> getAllValues<T>(String boxName) {
    try {
      final box = _getBox<T>(boxName);
      return box?.values.toList() ?? [];
    } catch (e) {
      AppLogger.e('Failed to get all values from $boxName', e);
      return [];
    }
  }

  @override
  Future<void> saveValue<T>(String boxName, String key, T value) async {
    try {
      final box = _getBox<T>(boxName);
      await box?.put(key, value);
      AppLogger.d('Saved value: $key to $boxName');
    } catch (e) {
      AppLogger.e('Failed to save value: $key to $boxName', e);
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  @override
  Future<void> saveAllValues<T>(String boxName, Map<String, T> entries) async {
    try {
      final box = _getBox<T>(boxName);
      await box?.putAll(entries);
      AppLogger.d('Saved ${entries.length} values to $boxName');
    } catch (e) {
      AppLogger.e('Failed to save values to $boxName', e);
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  @override
  Future<void> deleteValue(String boxName, String key) async {
    try {
      final box = _getBox<dynamic>(boxName);
      await box?.delete(key);
      AppLogger.d('Deleted value: $key from $boxName');
    } catch (e) {
      AppLogger.e('Failed to delete value: $key from $boxName', e);
      throw CacheException(message: 'Failed to delete data: $e');
    }
  }

  @override
  Future<void> clearBox(String boxName) async {
    try {
      final box = _getBox<dynamic>(boxName);
      await box?.clear();
      AppLogger.d('Cleared box: $boxName');
    } catch (e) {
      AppLogger.e('Failed to clear box: $boxName', e);
      throw CacheException(message: 'Failed to clear storage: $e');
    }
  }

  @override
  bool containsKey(String boxName, String key) {
    try {
      final box = _getBox<dynamic>(boxName);
      return box?.containsKey(key) ?? false;
    } catch (e) {
      AppLogger.e('Failed to check key: $key in $boxName', e);
      return false;
    }
  }

  @override
  Future<void> closeBox(String boxName) async {
    try {
      final box = _boxes.remove(boxName);
      await box?.close();
      AppLogger.d('Closed box: $boxName');
    } catch (e) {
      AppLogger.e('Failed to close box: $boxName', e);
    }
  }

  @override
  Future<void> closeAllBoxes() async {
    try {
      for (final box in _boxes.values) {
        await box.close();
      }
      _boxes.clear();
      await Hive.close();
      AppLogger.d('Closed all boxes');
    } catch (e) {
      AppLogger.e('Failed to close all boxes', e);
    }
  }

  @override
  Future<void> deleteBox(String boxName) async {
    try {
      await closeBox(boxName);
      await Hive.deleteBoxFromDisk(boxName);
      AppLogger.d('Deleted box from disk: $boxName');
    } catch (e) {
      AppLogger.e('Failed to delete box: $boxName', e);
      throw CacheException(message: 'Failed to delete storage: $e');
    }
  }

  @override
  Stream<BoxEvent> watchBox(String boxName, {String? key}) {
    final box = _getBox<dynamic>(boxName);
    if (box == null) {
      return const Stream.empty();
    }
    return box.watch(key: key);
  }
}

/// Helper class for caching with expiry
class CacheEntry<T> {
  CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiryDuration = AppConstants.cacheTimeout,
  });

  final T data;
  final DateTime timestamp;
  final Duration expiryDuration;

  bool get isExpired => DateTime.now().difference(timestamp) > expiryDuration;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataToJson) => {
    'data': dataToJson(data),
    'timestamp': timestamp.toIso8601String(),
    'expiryDuration': expiryDuration.inMilliseconds,
  };

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    return CacheEntry(
      data: dataFromJson(json['data'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDuration: Duration(milliseconds: json['expiryDuration'] as int),
    );
  }
}
