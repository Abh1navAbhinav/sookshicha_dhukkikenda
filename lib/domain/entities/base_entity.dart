/// Base entity class for domain layer
/// All domain entities should extend this class
abstract class BaseEntity {
  const BaseEntity();
}

/// Entity with an ID
abstract class IdentifiableEntity extends BaseEntity {
  const IdentifiableEntity({required this.id});

  final String id;
}

/// Entity with timestamps
abstract class TimestampedEntity extends IdentifiableEntity {
  const TimestampedEntity({required super.id, this.createdAt, this.updatedAt});

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
