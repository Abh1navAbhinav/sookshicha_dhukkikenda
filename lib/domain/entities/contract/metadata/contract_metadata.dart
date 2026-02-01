import 'package:equatable/equatable.dart';

/// Base class for all contract metadata.
///
/// Each contract type has specific metadata requirements:
/// - Reducing contracts need loan-specific data
/// - Growing contracts need investment-specific data
/// - Fixed contracts need subscription-specific data
///
/// This sealed class ensures type safety and exhaustive pattern matching.
sealed class ContractMetadata extends Equatable {
  const ContractMetadata();

  /// Factory constructor to create metadata from JSON
  factory ContractMetadata.fromJson(Map<String, dynamic> json) {
    final type = json['metadataType'] as String;

    switch (type) {
      case 'reducing':
        return ReducingContractMetadata.fromJson(json);
      case 'growing':
        return GrowingContractMetadata.fromJson(json);
      case 'fixed':
        return FixedContractMetadata.fromJson(json);
      default:
        throw ArgumentError('Unknown metadata type: $type');
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson();

  /// The type identifier for serialization
  String get metadataType;
}

/// Metadata for reducing contracts (Loans / EMIs).
///
/// Tracks loan-specific information like principal, interest rate,
/// tenure, and remaining balance.
final class ReducingContractMetadata extends ContractMetadata {
  const ReducingContractMetadata({
    required this.principalAmount,
    required this.interestRatePercent,
    required this.tenureMonths,
    required this.remainingBalance,
    required this.emiAmount,
    this.lenderName,
    this.loanType,
    this.accountNumber,
    this.paidInstallments = 0,
    this.prepaymentsMade = 0.0,
  });

  /// Original principal amount of the loan
  final double principalAmount;

  /// Annual interest rate in percentage (e.g., 8.5 for 8.5%)
  final double interestRatePercent;

  /// Total tenure in months
  final int tenureMonths;

  /// Current remaining balance
  final double remainingBalance;

  /// Monthly EMI amount
  final double emiAmount;

  /// Name of the lender/bank
  final String? lenderName;

  /// Type of loan (home, car, personal, education, etc.)
  final String? loanType;

  /// Loan account number for reference
  final String? accountNumber;

  /// Number of installments already paid
  final int paidInstallments;

  /// Total prepayments made towards the loan
  final double prepaymentsMade;

  @override
  String get metadataType => 'reducing';

  /// Remaining installments
  int get remainingInstallments => tenureMonths - paidInstallments;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercent =>
      tenureMonths > 0 ? paidInstallments / tenureMonths : 0.0;

  /// Total amount paid so far
  double get totalPaid => (paidInstallments * emiAmount) + prepaymentsMade;

  /// Creates a copy with updated fields
  ReducingContractMetadata copyWith({
    double? principalAmount,
    double? interestRatePercent,
    int? tenureMonths,
    double? remainingBalance,
    double? emiAmount,
    String? lenderName,
    String? loanType,
    String? accountNumber,
    int? paidInstallments,
    double? prepaymentsMade,
  }) {
    return ReducingContractMetadata(
      principalAmount: principalAmount ?? this.principalAmount,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      emiAmount: emiAmount ?? this.emiAmount,
      lenderName: lenderName ?? this.lenderName,
      loanType: loanType ?? this.loanType,
      accountNumber: accountNumber ?? this.accountNumber,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      prepaymentsMade: prepaymentsMade ?? this.prepaymentsMade,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'metadataType': metadataType,
      'principalAmount': principalAmount,
      'interestRatePercent': interestRatePercent,
      'tenureMonths': tenureMonths,
      'remainingBalance': remainingBalance,
      'emiAmount': emiAmount,
      'lenderName': lenderName,
      'loanType': loanType,
      'accountNumber': accountNumber,
      'paidInstallments': paidInstallments,
      'prepaymentsMade': prepaymentsMade,
    };
  }

  factory ReducingContractMetadata.fromJson(Map<String, dynamic> json) {
    return ReducingContractMetadata(
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRatePercent: (json['interestRatePercent'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      emiAmount: (json['emiAmount'] as num).toDouble(),
      lenderName: json['lenderName'] as String?,
      loanType: json['loanType'] as String?,
      accountNumber: json['accountNumber'] as String?,
      paidInstallments: json['paidInstallments'] as int? ?? 0,
      prepaymentsMade: (json['prepaymentsMade'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    principalAmount,
    interestRatePercent,
    tenureMonths,
    remainingBalance,
    emiAmount,
    lenderName,
    loanType,
    accountNumber,
    paidInstallments,
    prepaymentsMade,
  ];
}

/// Metadata for growing contracts (Savings / Investments).
///
/// Tracks investment-specific information like corpus, returns,
/// and contribution schedules.
final class GrowingContractMetadata extends ContractMetadata {
  const GrowingContractMetadata({
    required this.currentValue,
    required this.totalInvested,
    this.expectedReturnPercent,
    this.targetAmount,
    this.targetDate,
    this.investmentType,
    this.providerName,
    this.folioNumber,
    this.sipDate,
    this.assetAllocation,
    this.paidMonths = 0,
  });

  /// Current market value of the investment
  final double currentValue;

  /// Total amount invested so far
  final double totalInvested;

  /// Expected annual return percentage (for projections)
  final double? expectedReturnPercent;

  /// Target amount to reach (goal-based investing)
  final double? targetAmount;

  /// Target date to reach the goal
  final DateTime? targetDate;

  /// Type of investment (mutual_fund, sip, fd, rd, stocks, etc.)
  final String? investmentType;

  /// Name of the fund house/bank/provider
  final String? providerName;

  /// Folio or account number for reference
  final String? folioNumber;

  /// Day of month for SIP deduction (1-31)
  final int? sipDate;

  /// Asset allocation breakdown (e.g., {"equity": 0.6, "debt": 0.4})
  final Map<String, double>? assetAllocation;

  /// Number of months already invested
  final int paidMonths;

  @override
  String get metadataType => 'growing';

  /// Absolute returns (current value - invested amount)
  double get absoluteReturns => currentValue - totalInvested;

  /// Returns percentage
  double get returnsPercent =>
      totalInvested > 0 ? (absoluteReturns / totalInvested) * 100 : 0.0;

  /// Progress towards target (0.0 to 1.0)
  double? get targetProgress => targetAmount != null && targetAmount! > 0
      ? currentValue / targetAmount!
      : null;

  GrowingContractMetadata copyWith({
    double? currentValue,
    double? totalInvested,
    double? expectedReturnPercent,
    double? targetAmount,
    DateTime? targetDate,
    String? investmentType,
    String? providerName,
    String? folioNumber,
    int? sipDate,
    Map<String, double>? assetAllocation,
    int? paidMonths,
  }) {
    return GrowingContractMetadata(
      currentValue: currentValue ?? this.currentValue,
      totalInvested: totalInvested ?? this.totalInvested,
      expectedReturnPercent:
          expectedReturnPercent ?? this.expectedReturnPercent,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      investmentType: investmentType ?? this.investmentType,
      providerName: providerName ?? this.providerName,
      folioNumber: folioNumber ?? this.folioNumber,
      sipDate: sipDate ?? this.sipDate,
      assetAllocation: assetAllocation ?? this.assetAllocation,
      paidMonths: paidMonths ?? this.paidMonths,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'metadataType': metadataType,
      'currentValue': currentValue,
      'totalInvested': totalInvested,
      'expectedReturnPercent': expectedReturnPercent,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toIso8601String(),
      'investmentType': investmentType,
      'providerName': providerName,
      'folioNumber': folioNumber,
      'sipDate': sipDate,
      'assetAllocation': assetAllocation,
      'paidMonths': paidMonths,
    };
  }

  factory GrowingContractMetadata.fromJson(Map<String, dynamic> json) {
    return GrowingContractMetadata(
      currentValue: (json['currentValue'] as num).toDouble(),
      totalInvested: (json['totalInvested'] as num).toDouble(),
      expectedReturnPercent: (json['expectedReturnPercent'] as num?)
          ?.toDouble(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      investmentType: json['investmentType'] as String?,
      providerName: json['providerName'] as String?,
      folioNumber: json['folioNumber'] as String?,
      sipDate: json['sipDate'] as int?,
      assetAllocation: (json['assetAllocation'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      paidMonths: json['paidMonths'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    currentValue,
    totalInvested,
    expectedReturnPercent,
    targetAmount,
    targetDate,
    investmentType,
    providerName,
    folioNumber,
    sipDate,
    assetAllocation,
    paidMonths,
  ];
}

/// Metadata for fixed contracts (Insurance / Subscriptions).
///
/// Tracks subscription-specific information like billing cycles,
/// renewal dates, and coverage details.
final class FixedContractMetadata extends ContractMetadata {
  const FixedContractMetadata({
    required this.billingCycle,
    this.renewalDate,
    this.autoRenew = true,
    this.category,
    this.providerName,
    this.policyNumber,
    this.coverageAmount,
    this.beneficiaries,
    this.paymentMethod,
    this.reminderDays,
    this.isLiability = true,
  });

  /// Billing cycle (monthly, quarterly, yearly)
  final BillingCycle billingCycle;

  /// Next renewal date
  final DateTime? renewalDate;

  /// Whether the contract auto-renews
  final bool autoRenew;

  /// Category (insurance, subscription, utility, rent, etc.)
  final String? category;

  /// Service provider name
  final String? providerName;

  /// Policy/subscription ID for reference
  final String? policyNumber;

  /// Coverage amount (for insurance)
  final double? coverageAmount;

  /// List of beneficiaries (for insurance)
  final List<String>? beneficiaries;

  /// Payment method used
  final String? paymentMethod;

  /// Days before renewal to remind the user
  final int? reminderDays;

  /// Whether this is a liability (true) or an asset (false)
  final bool isLiability;

  @override
  String get metadataType => 'fixed';

  /// Check if renewal is due within the next n days
  bool isRenewalDueWithin(int days) {
    if (renewalDate == null) return false;
    final now = DateTime.now();
    final diff = renewalDate!.difference(now).inDays;
    return diff >= 0 && diff <= days;
  }

  /// Creates a copy with updated fields
  FixedContractMetadata copyWith({
    BillingCycle? billingCycle,
    DateTime? renewalDate,
    bool? autoRenew,
    String? category,
    String? providerName,
    String? policyNumber,
    double? coverageAmount,
    List<String>? beneficiaries,
    String? paymentMethod,
    int? reminderDays,
    bool? isLiability,
  }) {
    return FixedContractMetadata(
      billingCycle: billingCycle ?? this.billingCycle,
      renewalDate: renewalDate ?? this.renewalDate,
      autoRenew: autoRenew ?? this.autoRenew,
      category: category ?? this.category,
      providerName: providerName ?? this.providerName,
      policyNumber: policyNumber ?? this.policyNumber,
      coverageAmount: coverageAmount ?? this.coverageAmount,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reminderDays: reminderDays ?? this.reminderDays,
      isLiability: isLiability ?? this.isLiability,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'metadataType': metadataType,
      'billingCycle': billingCycle.value,
      'renewalDate': renewalDate?.toIso8601String(),
      'autoRenew': autoRenew,
      'category': category,
      'providerName': providerName,
      'policyNumber': policyNumber,
      'coverageAmount': coverageAmount,
      'beneficiaries': beneficiaries,
      'paymentMethod': paymentMethod,
      'reminderDays': reminderDays,
      'isLiability': isLiability,
    };
  }

  factory FixedContractMetadata.fromJson(Map<String, dynamic> json) {
    return FixedContractMetadata(
      billingCycle: BillingCycle.fromJson(json['billingCycle'] as String),
      renewalDate: json['renewalDate'] != null
          ? DateTime.parse(json['renewalDate'] as String)
          : null,
      autoRenew: json['autoRenew'] as bool? ?? true,
      category: json['category'] as String?,
      providerName: json['providerName'] as String?,
      policyNumber: json['policyNumber'] as String?,
      coverageAmount: (json['coverageAmount'] as num?)?.toDouble(),
      beneficiaries: (json['beneficiaries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      paymentMethod: json['paymentMethod'] as String?,
      reminderDays: json['reminderDays'] as int?,
      isLiability: json['isLiability'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    billingCycle,
    renewalDate,
    autoRenew,
    category,
    providerName,
    policyNumber,
    coverageAmount,
    beneficiaries,
    paymentMethod,
    reminderDays,
    isLiability,
  ];
}

/// Billing cycle for fixed contracts
enum BillingCycle {
  monthly('monthly', 1),
  quarterly('quarterly', 3),
  halfYearly('half_yearly', 6),
  yearly('yearly', 12);

  const BillingCycle(this.value, this.months);

  final String value;
  final int months;

  static BillingCycle fromJson(String value) {
    return BillingCycle.values.firstWhere(
      (cycle) => cycle.value == value,
      orElse: () => throw ArgumentError('Unknown BillingCycle: $value'),
    );
  }

  String toJson() => value;

  String get displayName {
    switch (this) {
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.halfYearly:
        return 'Half Yearly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }
}
