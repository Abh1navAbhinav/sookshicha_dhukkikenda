import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/contract/contract.dart';
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
      // Get current month info
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Fetch current snapshot or generate if not exists
      final snapshotResult = await _snapshotRepository.getSnapshotForMonth(
        currentMonth,
        currentYear,
      );

      // Fetch active contracts
      final contractsResult = await _contractRepository.getActiveContracts();

      // Fetch contracts ending soon
      final upcomingResult = await _contractRepository.getContractsEndingSoon(
        30,
      );

      // Handle results
      await snapshotResult.fold(
        (failure) async {
          // If no snapshot, try to generate one
          final contracts = await _contractRepository.getActiveContracts();
          final contractsList = contracts.fold(
            (_) => <Contract>[],
            (list) => list,
          );

          if (contractsList.isEmpty) {
            // No contracts, emit empty dashboard
            await _emitEmptyDashboard(currentMonth, currentYear);
          } else {
            // Generate snapshot from contracts
            await _generateAndEmitDashboard(
              currentMonth,
              currentYear,
              contractsList,
            );
          }
        },
        (snapshot) async {
          // We have a snapshot, build the state
          final nextThreeMonths = await _getNextThreeMonths(
            currentMonth,
            currentYear,
          );

          final activeCount = contractsResult.fold(
            (_) => 0,
            (list) => list.length,
          );

          final upcoming = upcomingResult.fold(
            (_) => <Contract>[],
            (list) => list,
          );

          emit(
            DashboardLoaded(
              currentSnapshot: snapshot,
              nextThreeMonths: nextThreeMonths,
              activeContractsCount: activeCount,
              upcomingContracts: upcoming,
            ),
          );
        },
      );
    } catch (e) {
      emit(DashboardError(message: 'Failed to load dashboard: $e'));
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// Generate empty dashboard for new users
  Future<void> _emitEmptyDashboard(int month, int year) async {
    final emptySnapshot = MonthlySnapshot.empty(
      month: month,
      year: year,
      totalIncome: 0,
    );

    emit(
      DashboardLoaded(
        currentSnapshot: emptySnapshot,
        nextThreeMonths: _generateEmptyNextMonths(month, year),
        activeContractsCount: 0,
        upcomingContracts: [],
      ),
    );
  }

  /// Generate dashboard from contracts when no snapshot exists
  Future<void> _generateAndEmitDashboard(
    int month,
    int year,
    List<Contract> contracts,
  ) async {
    // Use the execution engine to calculate snapshot
    const engine = MonthlyExecutionEngine();
    final snapshot = engine.executeMonth(
      contracts: contracts,
      month: month,
      year: year,
      totalIncome: 0, // User needs to set this separately
    );

    // Save the generated snapshot
    await _snapshotRepository.saveSnapshot(snapshot);

    final nextThreeMonths = await _getNextThreeMonths(month, year);

    emit(
      DashboardLoaded(
        currentSnapshot: snapshot,
        nextThreeMonths: nextThreeMonths,
        activeContractsCount: contracts.length,
        upcomingContracts: [],
      ),
    );
  }

  /// Get next 3 months snapshots or projections
  Future<List<MonthlySnapshot>> _getNextThreeMonths(
    int currentMonth,
    int currentYear,
  ) async {
    final projections = <MonthlySnapshot>[];

    for (int i = 1; i <= 3; i++) {
      var month = currentMonth + i;
      var year = currentYear;

      if (month > 12) {
        month -= 12;
        year += 1;
      }

      final result = await _snapshotRepository.getSnapshotForMonth(month, year);
      result.fold(
        (_) => projections.add(
          MonthlySnapshot.empty(month: month, year: year, totalIncome: 0),
        ),
        (snapshot) => projections.add(snapshot),
      );
    }

    return projections;
  }

  List<MonthlySnapshot> _generateEmptyNextMonths(
    int currentMonth,
    int currentYear,
  ) {
    final projections = <MonthlySnapshot>[];

    for (int i = 1; i <= 3; i++) {
      var month = currentMonth + i;
      var year = currentYear;

      if (month > 12) {
        month -= 12;
        year += 1;
      }

      projections.add(
        MonthlySnapshot.empty(month: month, year: year, totalIncome: 0),
      );
    }

    return projections;
  }
}
