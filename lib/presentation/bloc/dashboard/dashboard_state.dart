import 'package:equatable/equatable.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/snapshot/monthly_snapshot.dart';

/// Dashboard State
///
/// Represents the complete state of the dashboard screen.
/// Designed for minimal mental load - only essential data exposed.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state - before any data is loaded
final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading state - data is being fetched
final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Loaded state - all data successfully fetched
final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.currentSnapshot,
    required this.nextThreeMonths,
    required this.activeContractsCount,
    required this.upcomingContracts,
    this.pinnedContracts = const [],
    this.totalInvestment = 0,
    this.totalPendingDebt = 0,
    this.financialInsights = const [],
    this.debtClosureDate,
    this.projectedIncomeAtDebtClosure,
    this.growingContractsCount = 0,
    this.reducingContractsCount = 0,
    this.chartProjections = const [],
  });

  /// Current month's financial snapshot
  final MonthlySnapshot currentSnapshot;

  /// Preview of next 3 months
  final List<MonthlySnapshot> nextThreeMonths;

  /// Projections for chart (12 months)
  final List<MonthlySnapshot> chartProjections;

  /// Total active contracts count
  final int activeContractsCount;

  /// Contracts expiring soon (next 30 days)
  final List<Contract> upcomingContracts;

  /// Contracts pinned by user to dashboard
  final List<Contract> pinnedContracts;

  /// Total current investment value
  final double totalInvestment;

  /// Total outstanding debt (remaining principal)
  final double totalPendingDebt;

  /// List of text-based financial insights
  final List<String> financialInsights;

  /// Calculated date when all debts will be cleared
  final DateTime? debtClosureDate;

  /// Projected monthly income when all debts are cleared
  final double? projectedIncomeAtDebtClosure;

  /// Count of growing contracts (investments, savings)
  final int growingContractsCount;

  /// Count of reducing contracts (loans, EMIs)
  final int reducingContractsCount;

  // ============== Convenience Getters ==============

  /// The headline number - what's left after all obligations
  double get freeBalance => currentSnapshot.freeBalance;

  /// Monthly income from growing contracts (investments, SIPs)
  double get income => currentSnapshot.growingOutflow;

  /// Outflow from reducing contracts (loans, EMIs)
  double get mandatoryOutflow => currentSnapshot.reducingOutflow;

  /// Total wealth (investment corpus)
  double get wealth => currentSnapshot.totalWealth;

  /// Whether user is in deficit
  bool get isDeficit => freeBalance < 0;

  /// Current month display name (e.g., "January 2026")
  String get monthDisplay => currentSnapshot.displayMonth;

  /// Health status based on savings rate
  DashboardHealthStatus get healthStatus {
    final savingsRate = currentSnapshot.savingsRatePercent;
    if (savingsRate >= 30) return DashboardHealthStatus.excellent;
    if (savingsRate >= 20) return DashboardHealthStatus.good;
    if (savingsRate >= 10) return DashboardHealthStatus.fair;
    if (savingsRate >= 0) return DashboardHealthStatus.caution;
    return DashboardHealthStatus.critical;
  }

  @override
  List<Object?> get props => [
    currentSnapshot,
    nextThreeMonths,
    chartProjections,
    activeContractsCount,
    upcomingContracts,
    pinnedContracts,
    totalInvestment,
    totalPendingDebt,
    financialInsights,
    debtClosureDate,
    projectedIncomeAtDebtClosure,
    growingContractsCount,
    reducingContractsCount,
  ];
}

/// Error state - something went wrong
final class DashboardError extends DashboardState {
  const DashboardError({required this.message, this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}

/// Health status for visual feedback
enum DashboardHealthStatus {
  excellent, // 30%+ savings
  good, // 20-30% savings
  fair, // 10-20% savings
  caution, // 0-10% savings
  critical, // Deficit
}
