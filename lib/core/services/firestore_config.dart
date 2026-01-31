import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../utils/logger.dart';

/// Firebase Firestore persistence configuration and management.
///
/// Provides injectable service for Firestore offline persistence control:
/// - Persistence settings management
/// - Network toggle for testing
/// - Cache management utilities
///
/// ## Offline Persistence Strategy
///
/// Firestore SDK provides built-in offline support:
/// 1. **Local Cache**: All reads/writes are cached locally first
/// 2. **Optimistic Updates**: UI updates immediately from cache
/// 3. **Background Sync**: Changes sync to server when online
/// 4. **Conflict Resolution**: Server timestamp wins on conflicts
///
/// ## Cache Size
/// - Default: 100 MB
/// - Can be adjusted based on app needs
/// - Old data is automatically evicted when limit is reached
///
/// ## Network Behavior
/// - Reads from cache first, then network
/// - Writes queue locally when offline
/// - Automatic retry on reconnection
abstract class FirestorePersistenceManager {
  /// Configure Firestore with optimal settings.
  Future<void> initialize();

  /// Enable/disable network access (for testing).
  Future<void> setNetworkEnabled(bool enabled);

  /// Clear the local cache (for testing/debugging).
  Future<void> clearCache();

  /// Wait for pending writes to complete.
  Future<void> waitForPendingWrites();
}

/// Implementation of FirestorePersistenceManager.
@LazySingleton(as: FirestorePersistenceManager)
class FirestorePersistenceManagerImpl implements FirestorePersistenceManager {
  FirestorePersistenceManagerImpl(this._firestore);

  final FirebaseFirestore _firestore;

  /// Default cache size in bytes (100 MB)
  static const int _defaultCacheSizeBytes = 100 * 1024 * 1024;

  @override
  Future<void> initialize() async {
    try {
      // Configure Firestore settings
      _firestore.settings = const Settings(
        // Enable persistent cache for offline support
        persistenceEnabled: true,

        // Set cache size (100 MB)
        // Set to Settings.CACHE_SIZE_UNLIMITED for no limit
        cacheSizeBytes: _defaultCacheSizeBytes,

        // Enable SSL (default, but explicit for clarity)
        sslEnabled: true,
      );

      AppLogger.i('Firestore configured with offline persistence enabled');
      AppLogger.d('Cache size: ${_defaultCacheSizeBytes ~/ (1024 * 1024)} MB');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to configure Firestore', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setNetworkEnabled(bool enabled) async {
    try {
      if (enabled) {
        await _firestore.enableNetwork();
        AppLogger.d('Firestore network enabled');
      } else {
        await _firestore.disableNetwork();
        AppLogger.d('Firestore network disabled');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to toggle network', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _firestore.clearPersistence();
      AppLogger.d('Firestore cache cleared');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to clear cache', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> waitForPendingWrites() async {
    try {
      await _firestore.waitForPendingWrites();
      AppLogger.d('Firestore pending writes completed');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to wait for pending writes', e, stackTrace);
      rethrow;
    }
  }
}

/// Firestore source options for reads.
///
/// Use these to control read behavior:
/// - [cache] - Read from local cache only
/// - [server] - Read from server only (requires network)
/// - [cacheOrServer] - Read from cache first, fallback to server
enum FirestoreReadSource { cache, server, cacheOrServer }

/// Extension to convert FirestoreReadSource to SDK Source.
extension FirestoreReadSourceExtension on FirestoreReadSource {
  Source toFirestoreSource() {
    switch (this) {
      case FirestoreReadSource.cache:
        return Source.cache;
      case FirestoreReadSource.server:
        return Source.server;
      case FirestoreReadSource.cacheOrServer:
        return Source.serverAndCache;
    }
  }
}
