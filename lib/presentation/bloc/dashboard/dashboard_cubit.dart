import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/entities/snapshot/monthly_snapshot.dart';
import '../../../domain/repositories/contract_repository.dart';
import '../../../domain/repositories/monthly_snapshot_repository.dart';
import '../../../domain/usecases/monthly_execution_engine.dart';
import 'dashboard_state.dart';

/// Dashboard Cubit
///
/// Manages the dashboard state with clean separation of concerns.
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required ContractRepository contractRepository,
    required MonthlySnapshotRepository snapshotRepository,
  }) : _contractRepository = contractRepository,
       _snapshotRepository = snapshotRepository,
       super(const DashboardInitial());

  final ContractRepository _contractRepository;
  final MonthlySnapshotRepository _snapshotRepository;

  StreamSubscription<dynamic>? _contractsSubscription;

  /// Load all dashboard data
  Future<void> loadDashboard() async {
    // Start watching if not already
    _contractsSubscription ??= _contractRepository
        .watchActiveContracts()
        .listen(
          (_) => loadDashboard(), // Re-load when contracts change
        );

    emit(const DashboardLoading());

    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // 1. Fetch active contracts
      final contractsResult = await _contractRepository.getActiveContracts();
      final contractsList = contractsResult.fold(
        (failure) => <Contract>[],
        (list) => list,
      );

      // 2. Fetch or Generate current snapshot
      final snapshotResult = await _snapshotRepository.getSnapshotForMonth(
        currentMonth,
        currentYear,
      );

      MonthlySnapshot currentSnapshot = MonthlySnapshot.empty(
        month: currentMonth,
        year: currentYear,
        totalIncome: 0,
      );

      await snapshotResult.fold(
        (failure) async {
          if (contractsList.isNotEmpty) {
            const engine = MonthlyExecutionEngine();
            currentSnapshot = engine.executeMonth(
              contracts: contractsList,
              month: currentMonth,
              year: currentYear,
              totalIncome: 0,
            );
            await _snapshotRepository.saveSnapshot(currentSnapshot);
          }
        },
        (snapshot) async {
          const engine = MonthlyExecutionEngine();
          currentSnapshot = engine.executeMonth(
            contracts: contractsList,
            month: currentMonth,
            year: currentYear,
            totalIncome: snapshot.totalIncome,
          );

          if (currentSnapshot != snapshot) {
            await _snapshotRepository.saveSnapshot(currentSnapshot);
          }
        },
      );

      // 3. Projections for insights and charts (36 months)
      const engine = MonthlyExecutionEngine();
      final projectionResult = engine.generateProjection(
        contracts: contractsList,
        startMonth: currentMonth,
        startYear: currentYear,
        monthCount: 36,
        monthlyIncome: currentSnapshot.totalIncome,
      );
      final projections = projectionResult.snapshots;

      // 4. Fetch upcoming contracts
      final upcomingResult = await _contractRepository.getContractsEndingSoon(
        30,
      );
      final upcoming = upcomingResult.fold((_) => <Contract>[], (list) => list);

      // 5. Pinned Contracts
      final pinnedContracts = contractsList
          .where((c) => c.showOnDashboard)
          .toList();

      // 6. Total Debts Pending
      // 6. Total Debts Pending & Total Investment
      double totalPendingDebt = 0;
      double totalInvestment = 0;
      int maxRemainingMonths = 0;

      for (final contract in contractsList) {
        if (contract.type == ContractType.reducing) {
          final metadata = contract.reducingMetadata;
          if (metadata != null) {
            const engine = MonthlyExecutionEngine();
            final remainingMonths = engine.calculateRemainingTenure(
              balance: metadata.remainingBalance,
              annualInterestRate: metadata.interestRatePercent,
              emi: metadata.emiAmount,
            );

            if (remainingMonths > maxRemainingMonths) {
              maxRemainingMonths = remainingMonths;
            }

            totalPendingDebt += remainingMonths * metadata.emiAmount;
          }
        } else if (contract.type == ContractType.fixed) {
          final metadata = contract.fixedMetadata;
          if (metadata != null) {
            final value = metadata.coverageAmount ?? contract.monthlyAmount;

            if (metadata.isLiability) {
              totalPendingDebt += value;
            } else {
              totalInvestment += value;
            }
          }
        } else if (contract.type == ContractType.growing) {
          totalInvestment += contract.growingMetadata?.totalInvested ?? 0;
        }
      }

      // 7. Find Debt Closure Date
      DateTime? debtClosureDate;
      double? projectedIncomeAtDebtClosure;

      for (final snapshot in projections) {
        if (snapshot.reducingOutflow <= 1.0) {
          // Using 1.0 as buffer instead of 0.01
          debtClosureDate = DateTime(snapshot.year, snapshot.month);
          projectedIncomeAtDebtClosure = snapshot.growingOutflow;
          break;
        }
      }

      // 8. Generate Financial Insights
      final insights = <String>[];
      if (debtClosureDate != null) {
        final monthsUntilClosure =
            ((debtClosureDate.year - currentYear) * 12) +
            (debtClosureDate.month - currentMonth);
        if (monthsUntilClosure > 0) {
          insights.add(
            'If you stay the course, your debt will be cleared by ${_getMonthName(debtClosureDate.month)} ${debtClosureDate.year} ($monthsUntilClosure months).',
          );
          insights.add(
            'At that time, your monthly investment surplus will be ${_formatCurrency(projectedIncomeAtDebtClosure ?? 0)}.',
          );
        } else {
          insights.add(
            'Great news! You are projected to be debt-free this month.',
          );
        }
      } else if (totalPendingDebt > 0) {
        final years = maxRemainingMonths ~/ 12;
        final months = maxRemainingMonths % 12;
        final durationParts = <String>[];
        if (years > 0) durationParts.add('$years years');
        if (months > 0) durationParts.add('$months months');

        final durationStr = durationParts.join(' and ');

        insights.add(
          'Your current loans are projected to continue for another $durationStr.',
        );
      } else {
        insights.add('You have no active debts. Keep growing your wealth!');
      }

      // Year end insight
      try {
        final yearEndSnapshot = projections.firstWhere(
          (s) => s.month == 12 && s.year == currentYear,
        );
        insights.add(
          'By end of $currentYear, your remaining debt will be ${_formatCurrency(yearEndSnapshot.totalDebt)} and total wealth will be ${_formatCurrency(yearEndSnapshot.totalWealth)}.',
        );
      } catch (_) {
        // If projection doesn't reach year end
      }

      // 9. Calculate contract counts by type
      final growingCount = contractsList
          .where((c) => c.type == ContractType.growing)
          .length;
      final reducingCount = contractsList
          .where((c) => c.type == ContractType.reducing)
          .length;

      emit(
        DashboardLoaded(
          currentSnapshot: currentSnapshot,
          nextThreeMonths: projections.take(3).toList(),
          chartProjections: projections.take(12).toList(),
          activeContractsCount: contractsList.length,
          upcomingContracts: upcoming,
          pinnedContracts: pinnedContracts,
          totalInvestment: totalInvestment,
          totalPendingDebt: totalPendingDebt,
          growingContractsCount: growingCount,
          reducingContractsCount: reducingCount,
          financialInsights: insights,
          debtClosureDate: debtClosureDate,
          projectedIncomeAtDebtClosure: projectedIncomeAtDebtClosure,
        ),
      );
    } catch (e) {
      emit(DashboardError(message: 'Failed to load dashboard: $e'));
    }
  }

  String _getMonthName(int month) {
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

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboard();
  }

  @override
  Future<void> close() {
    _contractsSubscription?.cancel();
    return super.close();
  }
}
