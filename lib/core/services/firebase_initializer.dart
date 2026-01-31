import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:injectable/injectable.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';
import 'package:sookshicha_dhukkikenda/firebase_options.dart';

/// Service class for Firebase initialization and configuration
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;

  /// Initialize Firebase with the provided options
  /// Call this before runApp
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.w('Firebase already initialized');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      AppLogger.i('Firebase initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize Firebase', e);
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}

/// Module for registering Firebase dependencies
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth {
    if (!FirebaseInitializer.isInitialized) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'not-initialized',
        message: 'Firebase must be initialized before accessing FirebaseAuth',
      );
    }
    return FirebaseAuth.instance;
  }

  @lazySingleton
  FirebaseFirestore get firebaseFirestore {
    if (!FirebaseInitializer.isInitialized) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'not-initialized',
        message:
            'Firebase must be initialized before accessing FirebaseFirestore',
      );
    }
    return FirebaseFirestore.instance;
  }
}

/// Firestore settings configuration
class FirestoreConfig {
  FirestoreConfig._();

  /// Configure Firestore settings
  static void configure({
    bool persistenceEnabled = true,
    int cacheSizeBytes = 100000000, // 100 MB
  }) {
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: persistenceEnabled,
      cacheSizeBytes: cacheSizeBytes,
    );
    AppLogger.i('Firestore configured with persistence: $persistenceEnabled');
  }

  /// Enable offline persistence (for local-first support)
  static void enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    AppLogger.i('Firestore offline persistence enabled');
  }

  /// Disable network (for offline testing)
  static Future<void> disableNetwork() async {
    await FirebaseFirestore.instance.disableNetwork();
    AppLogger.i('Firestore network disabled');
  }

  /// Enable network
  static Future<void> enableNetwork() async {
    await FirebaseFirestore.instance.enableNetwork();
    AppLogger.i('Firestore network enabled');
  }

  /// Wait for pending writes to complete
  static Future<void> waitForPendingWrites() async {
    await FirebaseFirestore.instance.waitForPendingWrites();
    AppLogger.i('Firestore pending writes completed');
  }

  /// Clear persistence
  static Future<void> clearPersistence() async {
    await FirebaseFirestore.instance.clearPersistence();
    AppLogger.i('Firestore persistence cleared');
  }
}
