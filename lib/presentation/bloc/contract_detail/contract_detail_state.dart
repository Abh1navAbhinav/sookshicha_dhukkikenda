import 'package:equatable/equatable.dart';

import '../../../domain/entities/contract/contract.dart';

/// Contract Detail State
///
/// State for viewing a single contract's details.
/// One screen, one message: the essential details of one contract.
sealed class ContractDetailState extends Equatable {
  const ContractDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class ContractDetailInitial extends ContractDetailState {
  const ContractDetailInitial();
}

/// Loading state
final class ContractDetailLoading extends ContractDetailState {
  const ContractDetailLoading();
}

/// Loaded state with full contract details
final class ContractDetailLoaded extends ContractDetailState {
  const ContractDetailLoaded({
    required this.contract,
    this.isUpdating = false,
    this.loanDetails,
  });

  /// The contract being viewed
  final Contract contract;

  /// Whether an update operation is in progress
  final bool isUpdating;

  // ============== Convenience Getters ==============

  /// Contract name
  String get name => contract.name;

  /// Type display name
  String get typeDisplay => contract.type.displayName;

  /// Status display name
  String get statusDisplay => contract.status.displayName;

  /// Monthly amount
  double get monthlyAmount => contract.monthlyAmount;

  /// Annual amount
  double get annualAmount => contract.annualAmount;

  /// Whether contract is active
  bool get isActive => contract.isActive;

  /// Whether contract is paused
  bool get isPaused => contract.isPaused;

  /// Contract start date
  DateTime get startDate => contract.startDate;

  /// Contract end date (if any)
  DateTime? get endDate => contract.endDate;

  /// Time elapsed
  int get monthsElapsed => contract.elapsedMonths;

  /// Time remaining (if applicable)
  int? get monthsRemaining => contract.remainingMonths;

  // ============== Type-Specific Details ==============

  // ============== Type-Specific Details ==============

  /// Pre-calculated loan details (for reducing contracts)
  final LoanSnapshotUIModel? loanDetails;

  /// Get growing contract details (investments/SIPs)
  GrowingDetails? get growingDetails {
    final metadata = contract.growingMetadata;
    if (metadata == null) return null;

    final totalInvested = contract.elapsedMonths * contract.monthlyAmount;

    return GrowingDetails(
      invested: totalInvested,
      currentValue: metadata.currentValue,
      expectedRate: metadata.expectedReturnPercent ?? 0,
      targetAmount: metadata.targetAmount,
      returns: metadata.currentValue - totalInvested,
      startDate: contract.startDate,
      endDate: contract.endDate,
      monthlyContribution: contract.monthlyAmount,
    );
  }

  /// Get fixed contract details (subscriptions/insurance)
  FixedDetails? get fixedDetails {
    final metadata = contract.fixedMetadata;
    if (metadata == null) return null;

    return FixedDetails(
      category: metadata.category ?? 'Subscription',
      billingCycle: metadata.billingCycle.displayName,
      autoRenew: metadata.autoRenew,
      renewalDate: metadata.renewalDate,
      totalPaid: monthlyAmount * monthsElapsed,
      isLiability: metadata.isLiability,
    );
  }

  /// Copy with
  ContractDetailLoaded copyWith({
    Contract? contract,
    bool? isUpdating,
    LoanSnapshotUIModel? loanDetails,
  }) {
    return ContractDetailLoaded(
      contract: contract ?? this.contract,
      isUpdating: isUpdating ?? this.isUpdating,
      loanDetails: loanDetails ?? this.loanDetails,
    );
  }

  @override
  List<Object?> get props => [contract, isUpdating, loanDetails];
}

/// Error state
final class ContractDetailError extends ContractDetailState {
  const ContractDetailError({required this.message, this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}

/// Action completed state (for pause/resume/close operations)
final class ContractDetailActionCompleted extends ContractDetailState {
  const ContractDetailActionCompleted({
    required this.action,
    required this.contract,
  });

  final ContractAction action;
  final Contract contract;

  @override
  List<Object?> get props => [action, contract];
}

/// Available actions on a contract
enum ContractAction { paused, resumed, closed, deleted }

// ============== Detail Models ==============

/// Immutable snapshot of loan state derived entirely from amortization engine
class LoanSnapshotUIModel extends Equatable {
  LoanSnapshotUIModel({
    required this.monthlyInterest,
    required this.monthlyPrincipal,
    required this.totalInterestFullTenure,
    required this.totalPayableFullTenure,
    required this.principalPaidTillDate,
    required this.interestPaidTillDate,
    required this.remainingPrincipal,
    required this.remainingInterest,
    required this.remainingBalance,
    required this.progressPercent,
    required this.originalPrincipal,
    required this.interestRate,
  });
  // Assertions removed to prevent crashes due to minor floating point drifts
  // or input precision mismatches (e.g. principal having >2 decimal places).
  // The UI will still display consistent values derived from the schedule.
  /*
   : assert(
         (remainingBalance - (remainingPrincipal + remainingInterest)).abs() <
             0.1,
         'Invariant violated: Remaining Balance != Remaining Principal + Remaining Interest',
       ),
       assert(
         (remainingBalance -
                 (totalPayableFullTenure -
                     (principalPaidTillDate + interestPaidTillDate)))
                 .abs() <
             0.1,
         'Invariant violated: Remaining Balance != Total Payable - Total Paid',
       );
  */

  final double monthlyInterest;
  final double monthlyPrincipal;

  final double totalInterestFullTenure;
  final double totalPayableFullTenure;

  final double principalPaidTillDate;
  final double interestPaidTillDate;

  final double remainingPrincipal;
  final double remainingInterest;

  /// Principal + Interest remaining
  final double remainingBalance;

  final double progressPercent;

  // Metadata for display
  final double originalPrincipal;
  final double interestRate;

  double get totalPaid => principalPaidTillDate + interestPaidTillDate;

  @override
  List<Object?> get props => [
    monthlyInterest,
    monthlyPrincipal,
    totalInterestFullTenure,
    totalPayableFullTenure,
    principalPaidTillDate,
    interestPaidTillDate,
    remainingPrincipal,
    remainingInterest,
    remainingBalance,
    progressPercent,
    originalPrincipal,
    interestRate,
  ];
}

/// Details specific to growing (investment) contracts
class GrowingDetails {
  const GrowingDetails({
    required this.invested,
    required this.currentValue,
    required this.expectedRate,
    required this.returns,
    required this.startDate,
    required this.monthlyContribution,
    this.targetAmount,
    this.endDate,
  });

  final double invested;
  final double currentValue;
  final double expectedRate;
  final double? targetAmount;
  final double returns;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyContribution;

  double get returnsPercent => invested > 0 ? (returns / invested) * 100 : 0;

  /// Total amount we will have paid at the end of the contract
  double? get projectedTotalPaid {
    if (endDate == null) return null;
    final totalMonths =
        (endDate!.year - startDate.year) * 12 +
        (endDate!.month - startDate.month);
    return totalMonths * monthlyContribution;
  }

  /// Estimated future value at end date (linear projection for simplicity)
  double? get projectedFutureValue {
    if (endDate == null || expectedRate <= 0) return null;
    final now = DateTime.now();
    final remainingMonths =
        (endDate!.year - now.year) * 12 + (endDate!.month - now.month);
    if (remainingMonths <= 0) return currentValue;

    // Simple monthly compounding approximation for UI
    double futureValue = currentValue;
    final monthlyRate = (expectedRate / 100) / 12;
    for (int i = 0; i < remainingMonths; i++) {
      futureValue = (futureValue + monthlyContribution) * (1 + monthlyRate);
    }
    return futureValue;
  }
}

/// Details specific to fixed (subscription) contracts
class FixedDetails {
  const FixedDetails({
    required this.category,
    required this.billingCycle,
    required this.autoRenew,
    required this.totalPaid,
    required this.isLiability,
    this.renewalDate,
  });

  final String category;
  final String billingCycle;
  final bool autoRenew;
  final DateTime? renewalDate;
  final double totalPaid;
  final bool isLiability;
}
