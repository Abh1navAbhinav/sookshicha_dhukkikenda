import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/snapshot/monthly_snapshot.dart';
import '../../domain/repositories/monthly_snapshot_repository.dart';
import '../datasources/monthly_snapshot_firestore_datasource.dart';
import '../models/monthly_snapshot_dto.dart';

/// Implementation of MonthlySnapshotRepository using Firestore.
///
/// This repository implements the domain interface and handles:
/// - DTO to Entity mapping
/// - Exception to Failure conversion
/// - Aggregate calculations
/// - Offline-first behavior (via Firestore SDK)
///
/// ## Document ID Strategy
/// Uses YYYY-MM format (e.g., '2026-01') for:
/// - Natural chronological ordering
/// - Efficient range queries
/// - Idempotent upserts (same month = same document)
///
/// ## Error Handling Strategy
/// - Catches data layer exceptions
/// - Converts to domain-level Failures
/// - Returns Either with Failure or success value for explicit error handling
@LazySingleton(as: MonthlySnapshotRepository)
class MonthlySnapshotRepositoryImpl implements MonthlySnapshotRepository {
  MonthlySnapshotRepositoryImpl(this._dataSource);

  final MonthlySnapshotFirestoreDataSource _dataSource;

  @override
  Future<Either<Failure, MonthlySnapshot>> getSnapshotForMonth(
    int month,
    int year,
  ) async {
    try {
      final dto = await _dataSource.getSnapshotForMonth(month, year);
      if (dto == null) {
        return Left(
          NotFoundFailure(
            message: 'Snapshot not found for $month/$year',
            code: 'not_found',
          ),
        );
      }
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting snapshot', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlySnapshot>>> getSnapshotsInRange(
    int startMonth,
    int startYear,
    int endMonth,
    int endYear,
  ) async {
    try {
      final dtos = await _dataSource.getSnapshotsInRange(
        startMonth,
        startYear,
        endMonth,
        endYear,
      );
      final snapshots = dtos.map((dto) => dto.toEntity()).toList();
      return Right(snapshots);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting snapshots in range', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlySnapshot>>> getRecentSnapshots(
    int count,
  ) async {
    try {
      final dtos = await _dataSource.getRecentSnapshots(count);
      final snapshots = dtos.map((dto) => dto.toEntity()).toList();
      return Right(snapshots);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting recent snapshots', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlySnapshot>> getLatestSnapshot() async {
    try {
      final dto = await _dataSource.getLatestSnapshot();
      if (dto == null) {
        return const Left(
          NotFoundFailure(message: 'No snapshots found', code: 'not_found'),
        );
      }
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting latest snapshot', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlySnapshot>>> getSnapshotsForYear(
    int year,
  ) async {
    try {
      final dtos = await _dataSource.getSnapshotsForYear(year);
      final snapshots = dtos.map((dto) => dto.toEntity()).toList();
      return Right(snapshots);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting snapshots for year', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSnapshot(MonthlySnapshot snapshot) async {
    try {
      final dto = MonthlySnapshotDto.fromEntity(snapshot);
      await _dataSource.saveSnapshot(dto);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error saving snapshot', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSnapshot(int month, int year) async {
    try {
      await _dataSource.deleteSnapshot(month, year);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error deleting snapshot', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllSnapshots() async {
    try {
      await _dataSource.deleteAllSnapshots();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error deleting all snapshots', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, MonthlySnapshot?>> watchSnapshot(int month, int year) {
    return _dataSource.watchSnapshot(month, year).map((dto) {
      try {
        return Right<Failure, MonthlySnapshot?>(dto?.toEntity());
      } catch (e) {
        return Left<Failure, MonthlySnapshot?>(
          UnexpectedFailure(message: e.toString()),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<MonthlySnapshot>>> watchAllSnapshots() {
    return _dataSource.watchAllSnapshots().map((dtos) {
      try {
        final snapshots = dtos.map((dto) => dto.toEntity()).toList();
        return Right<Failure, List<MonthlySnapshot>>(snapshots);
      } catch (e) {
        return Left<Failure, List<MonthlySnapshot>>(
          UnexpectedFailure(message: e.toString()),
        );
      }
    });
  }

  @override
  Future<Either<Failure, bool>> hasSnapshot(int month, int year) async {
    try {
      final exists = await _dataSource.hasSnapshot(month, year);
      return Right(exists);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error checking snapshot existence',
        e,
        stackTrace,
      );
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> batchSaveSnapshots(
    List<MonthlySnapshot> snapshots,
  ) async {
    try {
      final dtos = snapshots.map(MonthlySnapshotDto.fromEntity).toList();
      await _dataSource.batchSaveSnapshots(dtos);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error batch saving snapshots', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlySnapshot>>> getDeficitSnapshots() async {
    try {
      final dtos = await _dataSource.getDeficitSnapshots();
      final snapshots = dtos.map((dto) => dto.toEntity()).toList();
      return Right(snapshots);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting deficit snapshots', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SnapshotAggregates>> getAggregateMetrics() async {
    try {
      final dtos = await _dataSource.getAllSnapshots();

      if (dtos.isEmpty) {
        return const Right(
          SnapshotAggregates(
            totalMonthsTracked: 0,
            averageMonthlyOutflow: 0,
            averageSavingsRate: 0,
            monthsWithDeficit: 0,
            highestOutflowMonth: null,
            lowestOutflowMonth: null,
          ),
        );
      }

      // Calculate aggregates
      double totalOutflow = 0;
      double totalSavingsRate = 0;
      int deficitCount = 0;
      double highestOutflow = 0;
      double lowestOutflow = double.infinity;
      String? highestOutflowMonth;
      String? lowestOutflowMonth;

      for (final dto in dtos) {
        totalOutflow += dto.mandatoryOutflow;

        // Calculate savings rate for this month
        if (dto.totalIncome > 0) {
          final freeBalance = dto.totalIncome - dto.mandatoryOutflow;
          totalSavingsRate += (freeBalance / dto.totalIncome) * 100;
        }

        // Check for deficit
        if (dto.mandatoryOutflow > dto.totalIncome) {
          deficitCount++;
        }

        // Track highest/lowest outflow
        if (dto.mandatoryOutflow > highestOutflow) {
          highestOutflow = dto.mandatoryOutflow;
          highestOutflowMonth = dto.documentId;
        }
        if (dto.mandatoryOutflow < lowestOutflow) {
          lowestOutflow = dto.mandatoryOutflow;
          lowestOutflowMonth = dto.documentId;
        }
      }

      return Right(
        SnapshotAggregates(
          totalMonthsTracked: dtos.length,
          averageMonthlyOutflow: totalOutflow / dtos.length,
          averageSavingsRate: totalSavingsRate / dtos.length,
          monthsWithDeficit: deficitCount,
          highestOutflowMonth: highestOutflowMonth,
          lowestOutflowMonth: lowestOutflowMonth,
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error calculating aggregates', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
