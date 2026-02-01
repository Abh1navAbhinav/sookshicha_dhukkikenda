import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

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
/// All business logic stays here - UI only renders state.
///
/// ## Design Principles
/// - Single Responsibility: Only manages dashboard data flow
/// - No UI logic: Cubit doesn't know about widgets
/// - Testable: All dependencies are injected
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

  /// Load all dashboard data
  ///
  /// Fetches current snapshot, future projections, and contract info.
  /// Emits loading then either loaded or error state.
  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // 1. Fetch active contracts (Always do this to ensure we have latest data)
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
          // No snapshot exists yet
          if (contractsList.isNotEmpty) {
            // Generate snapshot from contracts
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
          // Snapshot exists, but let's update it with current contracts
          // to ensure it's reflective of recent changes
          const engine = MonthlyExecutionEngine();
          currentSnapshot = engine.executeMonth(
            contracts: contractsList,
            month: currentMonth,
            year: currentYear,
            totalIncome: snapshot.totalIncome, // Preserving user-set income
          );

          if (currentSnapshot != snapshot) {
            await _snapshotRepository.saveSnapshot(currentSnapshot);
          }
        },
      );

      // 3. Fetch projections for next 3 months
      final nextThreeMonths = await _getNextThreeMonths(
        currentMonth,
        currentYear,
        contractsList,
      );

      // 4. Fetch upcoming contracts
      final upcomingResult = await _contractRepository.getContractsEndingSoon(
        30,
      );
      final upcoming = upcomingResult.fold((_) => <Contract>[], (list) => list);

      // 5. Calculate contract counts by type
      final growingCount = contractsList
          .where((c) => c.type == ContractType.growing)
          .length;
      final reducingCount = contractsList
          .where((c) => c.type == ContractType.reducing)
          .length;

      emit(
        DashboardLoaded(
          currentSnapshot: currentSnapshot,
          nextThreeMonths: nextThreeMonths,
          activeContractsCount: contractsList.length,
          upcomingContracts: upcoming,
          growingContractsCount: growingCount,
          reducingContractsCount: reducingCount,
        ),
      );
    } catch (e) {
      emit(DashboardError(message: 'Failed to load dashboard: $e'));
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// Get next 3 months snapshots or projections
  Future<List<MonthlySnapshot>> _getNextThreeMonths(
    int currentMonth,
    int currentYear,
    List<Contract> activeContracts,
  ) async {
    final projections = <MonthlySnapshot>[];
    const engine = MonthlyExecutionEngine();

    for (int i = 1; i <= 3; i++) {
      var month = currentMonth + i;
      var year = currentYear;

      if (month > 12) {
        month -= 12;
        year += 1;
      }

      final result = await _snapshotRepository.getSnapshotForMonth(month, year);
      result.fold((_) {
        // No snapshot, generate projection
        final projection = engine.executeMonth(
          contracts: activeContracts,
          month: month,
          year: year,
          totalIncome: 0,
        );
        projections.add(projection);
      }, (snapshot) => projections.add(snapshot));
    }

    return projections;
  }
}
