import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/contract/contract.dart';
import '../../domain/entities/contract/contract_status.dart';
import '../../domain/entities/contract/contract_type.dart';
import '../../domain/entities/contract/metadata/contract_metadata.dart';

/// Data Transfer Object for Contract entity.
///
/// This DTO handles the mapping between Firestore documents and domain entities.
/// It includes special handling for:
/// - Firestore Timestamps ↔ DateTime conversion
/// - Null safety for optional fields
/// - Server timestamps for audit fields
///
/// ## Firestore Document Structure
/// ```json
/// {
///   "name": "Home Loan - HDFC",
///   "type": "reducing",
///   "status": "active",
///   "startDate": Timestamp,
///   "endDate": Timestamp | null,
///   "monthlyAmount": 45000.0,
///   "metadata": { ... },
///   "description": "...",
///   "tags": ["loan", "home"],
///   "createdAt": Timestamp,
///   "updatedAt": Timestamp
/// }
/// ```
class ContractDto {
  const ContractDto({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.startDate,
    required this.monthlyAmount,
    required this.metadata,
    this.endDate,
    this.description,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyAmount;
  final Map<String, dynamic> metadata;
  final String? description;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create DTO from Firestore document.
  ///
  /// [doc] - Firestore document snapshot
  /// Handles Timestamp to DateTime conversion automatically.
  factory ContractDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ContractDto(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] as String,
      status: data['status'] as String,
      startDate: _timestampToDateTime(data['startDate']),
      endDate: data['endDate'] != null
          ? _timestampToDateTime(data['endDate'])
          : null,
      monthlyAmount: (data['monthlyAmount'] as num).toDouble(),
      metadata: data['metadata'] as Map<String, dynamic>,
      description: data['description'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      createdAt: data['createdAt'] != null
          ? _timestampToDateTime(data['createdAt'])
          : null,
      updatedAt: data['updatedAt'] != null
          ? _timestampToDateTime(data['updatedAt'])
          : null,
    );
  }

  /// Create DTO from raw Firestore map (used in queries).
  ///
  /// [map] - Map with document data including 'id' field
  factory ContractDto.fromMap(Map<String, dynamic> map) {
    return ContractDto(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      startDate: _timestampToDateTime(map['startDate']),
      endDate: map['endDate'] != null
          ? _timestampToDateTime(map['endDate'])
          : null,
      monthlyAmount: (map['monthlyAmount'] as num).toDouble(),
      metadata: map['metadata'] as Map<String, dynamic>,
      description: map['description'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      createdAt: map['createdAt'] != null
          ? _timestampToDateTime(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? _timestampToDateTime(map['updatedAt'])
          : null,
    );
  }

  /// Create DTO from domain entity.
  ///
  /// [contract] - Domain Contract entity
  factory ContractDto.fromEntity(Contract contract) {
    return ContractDto(
      id: contract.id,
      name: contract.name,
      type: contract.type.toJson(),
      status: contract.status.toJson(),
      startDate: contract.startDate,
      endDate: contract.endDate,
      monthlyAmount: contract.monthlyAmount,
      metadata: contract.metadata.toJson(),
      description: contract.description,
      tags: contract.tags,
      createdAt: contract.createdAt,
      updatedAt: contract.updatedAt,
    );
  }

  /// Convert DTO to domain entity.
  Contract toEntity() {
    return Contract(
      id: id,
      name: name,
      type: ContractType.fromJson(type),
      status: ContractStatus.fromJson(status),
      startDate: startDate,
      endDate: endDate,
      monthlyAmount: monthlyAmount,
      metadata: ContractMetadata.fromJson(metadata),
      description: description,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert DTO to Firestore map for writing.
  ///
  /// [useServerTimestamp] - If true, uses FieldValue.serverTimestamp() for
  /// createdAt/updatedAt. Set to true for create operations, false for reads.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = true}) {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'monthlyAmount': monthlyAmount,
      'metadata': metadata,
    };

    if (endDate != null) {
      map['endDate'] = Timestamp.fromDate(endDate!);
    }

    if (description != null) {
      map['description'] = description;
    }

    if (tags != null && tags!.isNotEmpty) {
      map['tags'] = tags;
    }

    // Don't include timestamps in write map - handled by FirestoreService
    return map;
  }

  /// Convert DTO to map for update operations.
  ///
  /// Only includes fields that should be updated (excludes createdAt).
  Map<String, dynamic> toUpdateMap() {
    return toFirestore(useServerTimestamp: false);
  }

  /// Helper to convert Firestore Timestamp or ISO string to DateTime.
  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    throw ArgumentError('Cannot convert $value to DateTime');
  }
}
