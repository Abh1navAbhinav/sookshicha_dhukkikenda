// Base model classes for data layer

/// Base model class for data layer
/// All data models should extend this class
abstract class BaseModel {
  const BaseModel();

  /// Convert the model to JSON
  Map<String, dynamic> toJson();
}

/// Model with an ID
abstract class IdentifiableModel extends BaseModel {
  const IdentifiableModel({required this.id});

  final String id;
}

/// Model with timestamps
abstract class TimestampedModel extends IdentifiableModel {
  const TimestampedModel({required super.id, this.createdAt, this.updatedAt});

  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Helper mixin for models that can be cached locally
mixin CacheableModel on BaseModel {
  /// Key used for local caching
  String get cacheKey;

  /// Check if the cached data is still valid
  bool isCacheValid(Duration maxAge, DateTime? cachedAt) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}
