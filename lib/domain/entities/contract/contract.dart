import 'package:equatable/equatable.dart';

import 'contract_status.dart';
import 'contract_type.dart';
import 'metadata/contract_metadata.dart';

/// Core domain entity representing a financial contract.
///
/// A Contract is the fundamental building block of the personal finance app.
/// It represents any recurring financial commitment or investment that the
/// user wants to track over time.
///
/// ## Design Philosophy
/// - **Immutability**: All fields are final. Changes create new instances.
/// - **Type Safety**: Uses sealed classes for metadata ensuring exhaustive handling.
/// - **Self-Contained**: Contains all information needed for monthly calculations.
///
/// ## Contract Types
/// - **Reducing**: Loans, EMIs where balance decreases
/// - **Growing**: Investments, savings where value increases
/// - **Fixed**: Subscriptions, insurance with constant payments
///
/// ## Example Usage
/// ```dart
/// final homeLoan = Contract(
///   id: 'loan_001',
///   name: 'Home Loan - HDFC',
///   type: ContractType.reducing,
///   status: ContractStatus.active,
///   startDate: DateTime(2023, 1, 1),
///   endDate: DateTime(2043, 1, 1),
///   monthlyAmount: 45000,
///   metadata: ReducingContractMetadata(
///     principalAmount: 5000000,
///     interestRatePercent: 8.5,
///     tenureMonths: 240,
///     remainingBalance: 4800000,
///     emiAmount: 45000,
///   ),
/// );
/// ```
final class Contract extends Equatable {
  const Contract({
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

  /// Unique identifier for the contract
  final String id;

  /// User-friendly name for the contract
  /// Examples: "Home Loan - HDFC", "Netflix Subscription", "SIP - Axis Bluechip"
  final String name;

  /// The type of contract determining its behavior
  final ContractType type;

  /// Current lifecycle status of the contract
  final ContractStatus status;

  /// Date when the contract started
  final DateTime startDate;

  /// Optional end date (null for indefinite contracts like subscriptions)
  final DateTime? endDate;

  /// The monthly amount involved in this contract
  /// - For reducing: EMI amount
  /// - For growing: Monthly investment
  /// - For fixed: Monthly payment (converted from any billing cycle)
  final double monthlyAmount;

  /// Type-specific metadata containing additional contract details
  /// Uses sealed classes for type safety
  final ContractMetadata metadata;

  /// Optional description for additional context
  final String? description;

  /// Optional tags for categorization and filtering
  final List<String>? tags;

  /// Timestamp when the contract was created in the system
  final DateTime? createdAt;

  /// Timestamp when the contract was last updated
  final DateTime? updatedAt;

  // ============== Computed Properties ==============

  /// Whether the contract has a defined end date
  bool get hasEndDate => endDate != null;

  /// Whether the contract is currently active
  bool get isActive => status == ContractStatus.active;

  /// Whether the contract is paused
  bool get isPaused => status == ContractStatus.paused;

  /// Whether the contract is closed
  bool get isClosed => status == ContractStatus.closed;

  /// Whether the contract is indefinite (no end date)
  bool get isIndefinite => endDate == null;

  /// Duration in months from start to end (null if indefinite)
  int? get durationMonths {
    if (endDate == null) return null;
    return _monthsBetween(startDate, endDate!);
  }

  /// Elapsed months since start date
  int get elapsedMonths {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    return _monthsBetween(startDate, now);
  }

  /// Remaining months until end date (null if indefinite)
  int? get remainingMonths {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return _monthsBetween(now, endDate!);
  }

  /// Whether the contract has ended based on end date
  bool get hasEnded {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Annual amount (monthly * 12)
  double get annualAmount => monthlyAmount * 12;

  /// Whether the contract allows updates based on status
  bool get canUpdate => status.allowsUpdates;

  // ============== Type-Safe Metadata Accessors ==============

  /// Get metadata as ReducingContractMetadata (returns null if type mismatch)
  ReducingContractMetadata? get reducingMetadata =>
      metadata is ReducingContractMetadata
      ? metadata as ReducingContractMetadata
      : null;

  /// Get metadata as GrowingContractMetadata (returns null if type mismatch)
  GrowingContractMetadata? get growingMetadata =>
      metadata is GrowingContractMetadata
      ? metadata as GrowingContractMetadata
      : null;

  /// Get metadata as FixedContractMetadata (returns null if type mismatch)
  FixedContractMetadata? get fixedMetadata => metadata is FixedContractMetadata
      ? metadata as FixedContractMetadata
      : null;

  // ============== Methods ==============

  /// Creates a copy with updated fields
  Contract copyWith({
    String? id,
    String? name,
    ContractType? type,
    ContractStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyAmount,
    ContractMetadata? metadata,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      metadata: metadata ?? this.metadata,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toJson(),
      'status': status.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'monthlyAmount': monthlyAmount,
      'metadata': metadata.toJson(),
      'description': description,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ContractType.fromJson(json['type'] as String),
      status: ContractStatus.fromJson(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      metadata: ContractMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Calculate months between two dates
  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    status,
    startDate,
    endDate,
    monthlyAmount,
    metadata,
    description,
    tags,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Contract(id: $id, name: $name, type: ${type.displayName}, '
        'status: ${status.displayName}, monthlyAmount: $monthlyAmount)';
  }
}
