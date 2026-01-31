/// Base data source interfaces for data layer
library;

/// Abstract class for remote data sources (API calls)
abstract class RemoteDataSource {
  const RemoteDataSource();
}

/// Abstract class for local data sources (Hive, SQLite, etc.)
abstract class LocalDataSource {
  const LocalDataSource();

  /// Clear all cached data
  Future<void> clearCache();

  /// Check if data exists in cache
  bool hasCache(String key);

  /// Get last sync timestamp
  DateTime? getLastSyncTime();
}
