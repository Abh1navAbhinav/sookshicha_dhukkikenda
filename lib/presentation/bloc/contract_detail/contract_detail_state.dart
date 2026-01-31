import 'package:equatable/equatable.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/metadata/contract_metadata.dart';

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
  const ContractDetailLoaded({required this.contract, this.isUpdating = false});

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

  /// Get reducing contract details (loans/EMIs)
  ReducingDetails? get reducingDetails {
    final metadata = contract.reducingMetadata;
    if (metadata == null) return null;

    return ReducingDetails(
      principalAmount: metadata.principalAmount,
      remainingBalance: metadata.remainingBalance,
      interestRate: metadata.interestRatePercent,
      tenureMonths: metadata.tenureMonths,
      emiAmount: metadata.emiAmount,
      totalInterest: _calculateTotalInterest(metadata),
      progressPercent: _calculateProgress(metadata),
    );
  }

  /// Get growing contract details (investments/SIPs)
  GrowingDetails? get growingDetails {
    final metadata = contract.growingMetadata;
    if (metadata == null) return null;

    return GrowingDetails(
      invested: metadata.totalInvested,
      currentValue: metadata.currentValue,
      expectedRate: metadata.expectedReturnPercent ?? 0,
      targetAmount: metadata.targetAmount,
      returns: metadata.currentValue - metadata.totalInvested,
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
    );
  }

  double _calculateTotalInterest(ReducingContractMetadata metadata) {
    return (metadata.emiAmount * metadata.tenureMonths) -
        metadata.principalAmount;
  }

  double _calculateProgress(ReducingContractMetadata metadata) {
    if (metadata.principalAmount == 0) return 0;
    final paid = metadata.principalAmount - metadata.remainingBalance;
    return (paid / metadata.principalAmount) * 100;
  }

  /// Copy with
  ContractDetailLoaded copyWith({Contract? contract, bool? isUpdating}) {
    return ContractDetailLoaded(
      contract: contract ?? this.contract,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [contract, isUpdating];
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
enum ContractAction { paused, resumed, closed }

// ============== Detail Models ==============

/// Details specific to reducing (loan) contracts
class ReducingDetails {
  const ReducingDetails({
    required this.principalAmount,
    required this.remainingBalance,
    required this.interestRate,
    required this.tenureMonths,
    required this.emiAmount,
    required this.totalInterest,
    required this.progressPercent,
  });

  final double principalAmount;
  final double remainingBalance;
  final double interestRate;
  final int tenureMonths;
  final double emiAmount;
  final double totalInterest;
  final double progressPercent;
}

/// Details specific to growing (investment) contracts
class GrowingDetails {
  const GrowingDetails({
    required this.invested,
    required this.currentValue,
    required this.expectedRate,
    required this.returns,
    this.targetAmount,
  });

  final double invested;
  final double currentValue;
  final double expectedRate;
  final double? targetAmount;
  final double returns;

  double get returnsPercent => invested > 0 ? (returns / invested) * 100 : 0;
}

/// Details specific to fixed (subscription) contracts
class FixedDetails {
  const FixedDetails({
    required this.category,
    required this.billingCycle,
    required this.autoRenew,
    required this.totalPaid,
    this.renewalDate,
  });

  final String category;
  final String billingCycle;
  final bool autoRenew;
  final DateTime? renewalDate;
  final double totalPaid;
}
