import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/snapshot/monthly_snapshot.dart';

/// Abstract repository for MonthlySnapshot operations.
///
/// This interface defines the contract for all monthly snapshot data operations.
/// Snapshots are point-in-time records of financial state, making them
/// suitable for historical analysis and reporting.
///
/// ## Design Decisions
/// - Uses composite key (month + year) for snapshot identification
/// - Supports range queries for historical analysis
/// - Provides optimized latest snapshot access
/// - User-scoped: All operations are implicitly scoped to the current user
///
/// ## Document ID Strategy
/// Uses format 'YYYY-MM' (e.g., '2026-01') as document ID for:
/// - Natural ordering
/// - Easy range queries
/// - Idempotent saves (same month always updates same doc)
///
/// ## Usage
/// ```dart
/// final result = await snapshotRepository.getSnapshotForMonth(1, 2026);
/// result.fold(
///   (failure) => handleError(failure),
///   (snapshot) => displaySnapshot(snapshot),
/// );
/// ```
abstract class MonthlySnapshotRepository {
  /// Get a snapshot for a specific month.
  ///
  /// [month] - Month number (1-12)
  /// [year] - Year (e.g., 2026)
  /// Returns [NotFoundFailure] if no snapshot exists for this month.
  Future<Either<Failure, MonthlySnapshot>> getSnapshotForMonth(
    int month,
    int year,
  );

  /// Get all snapshots within a date range.
  ///
  /// [startMonth] - Starting month (1-12)
  /// [startYear] - Starting year
  /// [endMonth] - Ending month (1-12)
  /// [endYear] - Ending year
  /// Returns snapshots ordered by date (ascending).
  Future<Either<Failure, List<MonthlySnapshot>>> getSnapshotsInRange(
    int startMonth,
    int startYear,
    int endMonth,
    int endYear,
  );

  /// Get the most recent N snapshots.
  ///
  /// [count] - Number of snapshots to retrieve
  /// Returns snapshots ordered by date (most recent first).
  Future<Either<Failure, List<MonthlySnapshot>>> getRecentSnapshots(int count);

  /// Get the latest snapshot.
  ///
  /// Returns the most recently generated snapshot.
  /// Returns [NotFoundFailure] if no snapshots exist.
  Future<Either<Failure, MonthlySnapshot>> getLatestSnapshot();

  /// Get all snapshots for a specific year.
  ///
  /// [year] - The year to get snapshots for
  /// Returns up to 12 snapshots ordered by month.
  Future<Either<Failure, List<MonthlySnapshot>>> getSnapshotsForYear(int year);

  /// Save a monthly snapshot.
  ///
  /// [snapshot] - The snapshot to save
  /// Uses upsert semantics - creates if new, updates if exists.
  /// The document ID is derived from month and year.
  Future<Either<Failure, void>> saveSnapshot(MonthlySnapshot snapshot);

  /// Delete a snapshot for a specific month.
  ///
  /// [month] - Month number (1-12)
  /// [year] - Year (e.g., 2026)
  /// Use with caution - typically snapshots should be preserved for history.
  Future<Either<Failure, void>> deleteSnapshot(int month, int year);

  /// Delete all snapshots (use with caution).
  ///
  /// Typically used only for testing or account reset.
  Future<Either<Failure, void>> deleteAllSnapshots();

  /// Stream a specific month's snapshot for real-time updates.
  ///
  /// [month] - Month number (1-12)
  /// [year] - Year (e.g., 2026)
  Stream<Either<Failure, MonthlySnapshot?>> watchSnapshot(int month, int year);

  /// Stream all snapshots for real-time updates.
  ///
  /// Returns a stream that emits whenever any snapshot changes.
  Stream<Either<Failure, List<MonthlySnapshot>>> watchAllSnapshots();

  /// Check if a snapshot exists for a specific month.
  ///
  /// [month] - Month number (1-12)
  /// [year] - Year (e.g., 2026)
  Future<Either<Failure, bool>> hasSnapshot(int month, int year);

  /// Batch save multiple snapshots.
  ///
  /// [snapshots] - List of snapshots to save
  /// All operations are performed atomically.
  Future<Either<Failure, void>> batchSaveSnapshots(
    List<MonthlySnapshot> snapshots,
  );

  /// Get snapshots with deficit (negative free balance).
  ///
  /// Useful for financial analysis and warnings.
  Future<Either<Failure, List<MonthlySnapshot>>> getDeficitSnapshots();

  /// Get total metrics across all snapshots.
  ///
  /// Returns aggregate metrics useful for dashboards.
  Future<Either<Failure, SnapshotAggregates>> getAggregateMetrics();
}

/// Aggregate metrics across all snapshots.
///
/// Used for dashboard summaries and trend analysis.
class SnapshotAggregates {
  const SnapshotAggregates({
    required this.totalMonthsTracked,
    required this.averageMonthlyOutflow,
    required this.averageSavingsRate,
    required this.monthsWithDeficit,
    required this.highestOutflowMonth,
    required this.lowestOutflowMonth,
  });

  final int totalMonthsTracked;
  final double averageMonthlyOutflow;
  final double averageSavingsRate;
  final int monthsWithDeficit;
  final String? highestOutflowMonth; // Format: 'YYYY-MM'
  final String? lowestOutflowMonth; // Format: 'YYYY-MM'
}
