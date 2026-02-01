import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/snapshot/monthly_snapshot.dart';

/// Data Transfer Object for MonthlySnapshot entity.
///
/// This DTO handles the mapping between Firestore documents and domain entities.
/// It includes special handling for:
/// - Composite document IDs (YYYY-MM format)
/// - Firestore Timestamps ↔ DateTime conversion
/// - Nested ContractContribution serialization
///
/// ## Document ID Strategy
/// Uses format 'YYYY-MM' (e.g., '2026-01') as document ID:
/// - Enables natural chronological ordering
/// - Supports efficient range queries with string comparison
/// - Ensures idempotent updates (same month = same document)
///
/// ## Firestore Document Structure
/// ```json
/// {
///   "month": 1,
///   "year": 2026,
///   "totalIncome": 100000.0,
///   "mandatoryOutflow": 65000.0,
///   "activeContractCount": 5,
///   "reducingOutflow": 45000.0,
///   "growingOutflow": 15000.0,
///   "fixedOutflow": 5000.0,
///   "contractBreakdown": [...],
///   "generatedAt": Timestamp
/// }
/// ```
class MonthlySnapshotDto {
  const MonthlySnapshotDto({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.mandatoryOutflow,
    required this.activeContractCount,
    required this.reducingOutflow,
    required this.growingOutflow,
    required this.fixedOutflow,
    required this.totalWealth,
    this.contractBreakdown,
    this.generatedAt,
  });

  final int month;
  final int year;
  final double totalIncome;
  final double mandatoryOutflow;
  final int activeContractCount;
  final double reducingOutflow;
  final double growingOutflow;
  final double fixedOutflow;
  final double totalWealth;
  final List<ContractContributionDto>? contractBreakdown;
  final DateTime? generatedAt;

  /// Generate document ID from month and year.
  ///
  /// Returns format: 'YYYY-MM' (e.g., '2026-01', '2026-12')
  String get documentId =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  /// Create document ID from month and year.
  static String createDocumentId(int month, int year) {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }

  /// Parse document ID to extract month and year.
  static ({int month, int year}) parseDocumentId(String docId) {
    final parts = docId.split('-');
    return (month: int.parse(parts[1]), year: int.parse(parts[0]));
  }

  /// Create DTO from Firestore document.
  factory MonthlySnapshotDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MonthlySnapshotDto._fromData(data);
  }

  /// Create DTO from Firestore map (used in queries).
  factory MonthlySnapshotDto.fromMap(Map<String, dynamic> map) {
    return MonthlySnapshotDto._fromData(map);
  }

  /// Internal factory to parse data map.
  factory MonthlySnapshotDto._fromData(Map<String, dynamic> data) {
    final breakdown = data['contractBreakdown'] as List<dynamic>?;
    return MonthlySnapshotDto(
      month: data['month'] as int,
      year: data['year'] as int,
      totalIncome: (data['totalIncome'] as num).toDouble(),
      mandatoryOutflow: (data['mandatoryOutflow'] as num).toDouble(),
      activeContractCount: data['activeContractCount'] as int,
      reducingOutflow: (data['reducingOutflow'] as num).toDouble(),
      growingOutflow: (data['growingOutflow'] as num).toDouble(),
      fixedOutflow: (data['fixedOutflow'] as num).toDouble(),
      totalWealth: (data['totalWealth'] as num?)?.toDouble() ?? 0.0,
      contractBreakdown: breakdown
          ?.map(
            (e) => ContractContributionDto.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
      generatedAt: data['generatedAt'] != null
          ? _timestampToDateTime(data['generatedAt'])
          : null,
    );
  }

  /// Create DTO from domain entity.
  factory MonthlySnapshotDto.fromEntity(MonthlySnapshot snapshot) {
    return MonthlySnapshotDto(
      month: snapshot.month,
      year: snapshot.year,
      totalIncome: snapshot.totalIncome,
      mandatoryOutflow: snapshot.mandatoryOutflow,
      activeContractCount: snapshot.activeContractCount,
      reducingOutflow: snapshot.reducingOutflow,
      growingOutflow: snapshot.growingOutflow,
      fixedOutflow: snapshot.fixedOutflow,
      totalWealth: snapshot.totalWealth,
      contractBreakdown: snapshot.contractBreakdown
          ?.map(ContractContributionDto.fromEntity)
          .toList(),
      generatedAt: snapshot.generatedAt,
    );
  }

  /// Convert DTO to domain entity.
  MonthlySnapshot toEntity() {
    return MonthlySnapshot(
      month: month,
      year: year,
      totalIncome: totalIncome,
      mandatoryOutflow: mandatoryOutflow,
      activeContractCount: activeContractCount,
      reducingOutflow: reducingOutflow,
      growingOutflow: growingOutflow,
      fixedOutflow: fixedOutflow,
      totalWealth: totalWealth,
      contractBreakdown: contractBreakdown
          ?.map((dto) => dto.toEntity())
          .toList(),
      generatedAt: generatedAt,
    );
  }

  /// Convert DTO to Firestore map for writing.
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'month': month,
      'year': year,
      'totalIncome': totalIncome,
      'mandatoryOutflow': mandatoryOutflow,
      'activeContractCount': activeContractCount,
      'reducingOutflow': reducingOutflow,
      'growingOutflow': growingOutflow,
      'fixedOutflow': fixedOutflow,
      'totalWealth': totalWealth,
    };

    if (contractBreakdown != null && contractBreakdown!.isNotEmpty) {
      map['contractBreakdown'] = contractBreakdown!
          .map((dto) => dto.toFirestore())
          .toList();
    }

    if (generatedAt != null) {
      map['generatedAt'] = Timestamp.fromDate(generatedAt!);
    }

    return map;
  }

  /// Helper to convert Firestore Timestamp to DateTime.
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

/// DTO for ContractContribution (nested within MonthlySnapshot).
class ContractContributionDto {
  const ContractContributionDto({
    required this.contractId,
    required this.contractName,
    required this.contractType,
    required this.amount,
    this.principalPortion,
    this.interestPortion,
    this.newBalance,
    this.newInvestedTotal,
  });

  final String contractId;
  final String contractName;
  final String contractType;
  final double amount;
  final double? principalPortion;
  final double? interestPortion;
  final double? newBalance;
  final double? newInvestedTotal;

  factory ContractContributionDto.fromMap(Map<String, dynamic> map) {
    return ContractContributionDto(
      contractId: map['contractId'] as String,
      contractName: map['contractName'] as String,
      contractType: map['contractType'] as String,
      amount: (map['amount'] as num).toDouble(),
      principalPortion: (map['principalPortion'] as num?)?.toDouble(),
      interestPortion: (map['interestPortion'] as num?)?.toDouble(),
      newBalance: (map['newBalance'] as num?)?.toDouble(),
      newInvestedTotal: (map['newInvestedTotal'] as num?)?.toDouble(),
    );
  }

  factory ContractContributionDto.fromEntity(ContractContribution entity) {
    return ContractContributionDto(
      contractId: entity.contractId,
      contractName: entity.contractName,
      contractType: entity.contractType,
      amount: entity.amount,
      principalPortion: entity.principalPortion,
      interestPortion: entity.interestPortion,
      newBalance: entity.newBalance,
      newInvestedTotal: entity.newInvestedTotal,
    );
  }

  ContractContribution toEntity() {
    return ContractContribution(
      contractId: contractId,
      contractName: contractName,
      contractType: contractType,
      amount: amount,
      principalPortion: principalPortion,
      interestPortion: interestPortion,
      newBalance: newBalance,
      newInvestedTotal: newInvestedTotal,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'contractId': contractId,
      'contractName': contractName,
      'contractType': contractType,
      'amount': amount,
    };

    if (principalPortion != null) map['principalPortion'] = principalPortion;
    if (interestPortion != null) map['interestPortion'] = interestPortion;
    if (newBalance != null) map['newBalance'] = newBalance;
    if (newInvestedTotal != null) map['newInvestedTotal'] = newInvestedTotal;

    return map;
  }
}
