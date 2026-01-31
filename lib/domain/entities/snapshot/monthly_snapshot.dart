import 'package:equatable/equatable.dart';

/// Represents a financial snapshot for a specific month.
///
/// A MonthlySnapshot captures the complete financial state at a point in time,
/// calculated deterministically from active contracts. No manual input required.
///
/// ## Design Philosophy
/// - **Immutability**: All fields are final, computed from contract state.
/// - **Deterministic**: Same contracts always produce the same snapshot.
/// - **Self-Contained**: Contains all financial metrics for the month.
///
/// ## Key Metrics
/// - **Total Income**: Not tracked from contracts (must be provided externally)
/// - **Mandatory Outflow**: All payments due this month
/// - **Free Balance**: Income minus mandatory outflow
/// - **Active Contract Count**: Number of active contracts
///
/// ## Contract Type Impact
/// - **Reducing**: EMI payments reduce remaining balance
/// - **Growing**: SIP amounts add to invested corpus
/// - **Fixed**: Subscription/insurance add to outflow
final class MonthlySnapshot extends Equatable {
  const MonthlySnapshot({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.mandatoryOutflow,
    required this.activeContractCount,
    required this.reducingOutflow,
    required this.growingOutflow,
    required this.fixedOutflow,
    this.contractBreakdown,
    this.generatedAt,
  });

  /// Month (1-12)
  final int month;

  /// Year (e.g., 2026)
  final int year;

  /// Total income for the month (provided externally or from income contracts)
  final double totalIncome;

  /// Total mandatory outflow (sum of all active contract payments)
  /// Includes: EMIs + SIPs + Subscriptions
  final double mandatoryOutflow;

  /// Number of active contracts in this month
  final int activeContractCount;

  /// Outflow from reducing contracts (loans/EMIs)
  final double reducingOutflow;

  /// Outflow from growing contracts (SIPs/investments)
  final double growingOutflow;

  /// Outflow from fixed contracts (subscriptions/insurance)
  final double fixedOutflow;

  /// Breakdown of each contract's contribution (optional detail)
  final List<ContractContribution>? contractBreakdown;

  /// Timestamp when this snapshot was generated
  final DateTime? generatedAt;

  // ============== Computed Properties ==============

  /// Free balance after all mandatory payments
  /// Can be negative if outflow exceeds income
  double get freeBalance => totalIncome - mandatoryOutflow;

  /// Savings rate as percentage of income
  double get savingsRatePercent =>
      totalIncome > 0 ? (freeBalance / totalIncome) * 100 : 0.0;

  /// Whether free balance is negative (overspending)
  bool get isDeficit => freeBalance < 0;

  /// Whether no active contracts exist
  bool get hasNoContracts => activeContractCount == 0;

  /// DateTime representation of the month
  DateTime get monthDate => DateTime(year, month);

  /// Human-readable month name
  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Display string like "January 2026"
  String get displayMonth => '$monthName $year';

  // ============== Factory Constructors ==============

  /// Creates an empty snapshot for a given month (no contracts)
  factory MonthlySnapshot.empty({
    required int month,
    required int year,
    double totalIncome = 0.0,
  }) {
    return MonthlySnapshot(
      month: month,
      year: year,
      totalIncome: totalIncome,
      mandatoryOutflow: 0.0,
      activeContractCount: 0,
      reducingOutflow: 0.0,
      growingOutflow: 0.0,
      fixedOutflow: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  // ============== Methods ==============

  /// Creates a copy with updated fields
  MonthlySnapshot copyWith({
    int? month,
    int? year,
    double? totalIncome,
    double? mandatoryOutflow,
    int? activeContractCount,
    double? reducingOutflow,
    double? growingOutflow,
    double? fixedOutflow,
    List<ContractContribution>? contractBreakdown,
    DateTime? generatedAt,
  }) {
    return MonthlySnapshot(
      month: month ?? this.month,
      year: year ?? this.year,
      totalIncome: totalIncome ?? this.totalIncome,
      mandatoryOutflow: mandatoryOutflow ?? this.mandatoryOutflow,
      activeContractCount: activeContractCount ?? this.activeContractCount,
      reducingOutflow: reducingOutflow ?? this.reducingOutflow,
      growingOutflow: growingOutflow ?? this.growingOutflow,
      fixedOutflow: fixedOutflow ?? this.fixedOutflow,
      contractBreakdown: contractBreakdown ?? this.contractBreakdown,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'totalIncome': totalIncome,
      'mandatoryOutflow': mandatoryOutflow,
      'freeBalance': freeBalance,
      'activeContractCount': activeContractCount,
      'reducingOutflow': reducingOutflow,
      'growingOutflow': growingOutflow,
      'fixedOutflow': fixedOutflow,
      'contractBreakdown': contractBreakdown?.map((c) => c.toJson()).toList(),
      'generatedAt': generatedAt?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory MonthlySnapshot.fromJson(Map<String, dynamic> json) {
    return MonthlySnapshot(
      month: json['month'] as int,
      year: json['year'] as int,
      totalIncome: (json['totalIncome'] as num).toDouble(),
      mandatoryOutflow: (json['mandatoryOutflow'] as num).toDouble(),
      activeContractCount: json['activeContractCount'] as int,
      reducingOutflow: (json['reducingOutflow'] as num).toDouble(),
      growingOutflow: (json['growingOutflow'] as num).toDouble(),
      fixedOutflow: (json['fixedOutflow'] as num).toDouble(),
      contractBreakdown: (json['contractBreakdown'] as List<dynamic>?)
          ?.map((e) => ContractContribution.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    month,
    year,
    totalIncome,
    mandatoryOutflow,
    activeContractCount,
    reducingOutflow,
    growingOutflow,
    fixedOutflow,
    contractBreakdown,
    generatedAt,
  ];

  @override
  String toString() {
    return 'MonthlySnapshot($displayMonth: income=$totalIncome, '
        'outflow=$mandatoryOutflow, free=$freeBalance, '
        'contracts=$activeContractCount)';
  }
}

/// Represents a single contract's contribution to the monthly snapshot.
///
/// Provides detailed breakdown of what each contract contributes.
final class ContractContribution extends Equatable {
  const ContractContribution({
    required this.contractId,
    required this.contractName,
    required this.contractType,
    required this.amount,
    this.principalPortion,
    this.interestPortion,
    this.newBalance,
    this.newInvestedTotal,
  });

  /// ID of the contributing contract
  final String contractId;

  /// Name of the contract for display
  final String contractName;

  /// Type of contract (reducing, growing, fixed)
  final String contractType;

  /// Amount paid/invested this month
  final double amount;

  /// For reducing: principal portion of EMI
  final double? principalPortion;

  /// For reducing: interest portion of EMI
  final double? interestPortion;

  /// For reducing: new remaining balance after payment
  final double? newBalance;

  /// For growing: new total invested after this month
  final double? newInvestedTotal;

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'contractName': contractName,
      'contractType': contractType,
      'amount': amount,
      'principalPortion': principalPortion,
      'interestPortion': interestPortion,
      'newBalance': newBalance,
      'newInvestedTotal': newInvestedTotal,
    };
  }

  factory ContractContribution.fromJson(Map<String, dynamic> json) {
    return ContractContribution(
      contractId: json['contractId'] as String,
      contractName: json['contractName'] as String,
      contractType: json['contractType'] as String,
      amount: (json['amount'] as num).toDouble(),
      principalPortion: (json['principalPortion'] as num?)?.toDouble(),
      interestPortion: (json['interestPortion'] as num?)?.toDouble(),
      newBalance: (json['newBalance'] as num?)?.toDouble(),
      newInvestedTotal: (json['newInvestedTotal'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    contractId,
    contractName,
    contractType,
    amount,
    principalPortion,
    interestPortion,
    newBalance,
    newInvestedTotal,
  ];
}
