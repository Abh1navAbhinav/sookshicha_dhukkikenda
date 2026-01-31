import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/contract/contract.dart';
import '../../domain/entities/contract/contract_status.dart';
import '../../domain/entities/contract/contract_type.dart';
import '../../domain/repositories/contract_repository.dart';
import '../datasources/contract_firestore_datasource.dart';
import '../models/contract_dto.dart';

/// Implementation of ContractRepository using Firestore.
///
/// This repository implements the domain interface and handles:
/// - DTO to Entity mapping
/// - Exception to Failure conversion
/// - Offline-first behavior (via Firestore SDK)
///
/// ## Error Handling Strategy
/// - Catches data layer exceptions
/// - Converts to domain-level Failures
/// - Returns Either with Failure or success value for explicit error handling
///
/// ## Offline Behavior
/// Firestore SDK handles offline persistence automatically when enabled.
/// Operations queue locally and sync when online.
@LazySingleton(as: ContractRepository)
class ContractRepositoryImpl implements ContractRepository {
  ContractRepositoryImpl(this._dataSource);

  final ContractFirestoreDataSource _dataSource;

  @override
  Future<Either<Failure, List<Contract>>> getAllContracts() async {
    try {
      final dtos = await _dataSource.getAllContracts();
      final contracts = dtos.map((dto) => dto.toEntity()).toList();
      return Right(contracts);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting all contracts', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contract>>> getContractsByStatus(
    ContractStatus status,
  ) async {
    try {
      final dtos = await _dataSource.getContractsByStatus(status.toJson());
      final contracts = dtos.map((dto) => dto.toEntity()).toList();
      return Right(contracts);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error getting contracts by status',
        e,
        stackTrace,
      );
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contract>>> getContractsByType(
    ContractType type,
  ) async {
    try {
      final dtos = await _dataSource.getContractsByType(type.toJson());
      final contracts = dtos.map((dto) => dto.toEntity()).toList();
      return Right(contracts);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error getting contracts by type', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contract>>> getActiveContracts() async {
    return getContractsByStatus(ContractStatus.active);
  }

  @override
  Future<Either<Failure, Contract>> getContractById(String contractId) async {
    try {
      final dto = await _dataSource.getContractById(contractId);
      if (dto == null) {
        return Left(
          NotFoundFailure(
            message: 'Contract not found: $contractId',
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
      AppLogger.e('Unexpected error getting contract by ID', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createContract(Contract contract) async {
    try {
      final dto = ContractDto.fromEntity(contract);
      final id = await _dataSource.createContract(dto);
      return Right(id);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error creating contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateContract(Contract contract) async {
    try {
      final dto = ContractDto.fromEntity(contract);
      await _dataSource.updateContract(dto);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error updating contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContract(String contractId) async {
    try {
      await _dataSource.deleteContract(contractId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error deleting contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> closeContract(String contractId) async {
    try {
      await _dataSource.updateContractStatus(
        contractId,
        ContractStatus.closed.toJson(),
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error closing contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pauseContract(String contractId) async {
    try {
      await _dataSource.updateContractStatus(
        contractId,
        ContractStatus.paused.toJson(),
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error pausing contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resumeContract(String contractId) async {
    try {
      await _dataSource.updateContractStatus(
        contractId,
        ContractStatus.active.toJson(),
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error resuming contract', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Contract>>> watchAllContracts() {
    return _dataSource.watchAllContracts().map((dtos) {
      try {
        final contracts = dtos.map((dto) => dto.toEntity()).toList();
        return Right<Failure, List<Contract>>(contracts);
      } catch (e) {
        return Left<Failure, List<Contract>>(
          UnexpectedFailure(message: e.toString()),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<Contract>>> watchActiveContracts() {
    return _dataSource
        .watchContractsByStatus(ContractStatus.active.toJson())
        .map((dtos) {
          try {
            final contracts = dtos.map((dto) => dto.toEntity()).toList();
            return Right<Failure, List<Contract>>(contracts);
          } catch (e) {
            return Left<Failure, List<Contract>>(
              UnexpectedFailure(message: e.toString()),
            );
          }
        });
  }

  @override
  Stream<Either<Failure, Contract>> watchContract(String contractId) {
    return _dataSource.watchContract(contractId).map((dto) {
      try {
        if (dto == null) {
          return Left<Failure, Contract>(
            NotFoundFailure(
              message: 'Contract not found: $contractId',
              code: 'not_found',
            ),
          );
        }
        return Right<Failure, Contract>(dto.toEntity());
      } catch (e) {
        return Left<Failure, Contract>(
          UnexpectedFailure(message: e.toString()),
        );
      }
    });
  }

  @override
  Future<Either<Failure, void>> batchUpdateContracts(
    List<Contract> contracts,
  ) async {
    try {
      final dtos = contracts.map(ContractDto.fromEntity).toList();
      await _dataSource.batchUpdateContracts(dtos);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e('Unexpected error batch updating contracts', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contract>>> getContractsEndingSoon(
    int days,
  ) async {
    try {
      final dtos = await _dataSource.getContractsEndingSoon(days);
      final contracts = dtos.map((dto) => dto.toEntity()).toList();
      return Right(contracts);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error getting contracts ending soon',
        e,
        stackTrace,
      );
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
