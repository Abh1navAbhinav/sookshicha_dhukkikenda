import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/contract/contract.dart';
import '../entities/contract/contract_status.dart';
import '../entities/contract/contract_type.dart';

/// Abstract repository for Contract operations.
///
/// This interface defines the contract for all contract-related data operations.
/// It follows the Repository pattern from Clean Architecture, keeping the
/// domain layer independent of data source implementations.
///
/// ## Design Decisions
/// - Uses [Either] from dartz for explicit error handling
/// - Provides both one-time fetch and stream-based methods
/// - Supports filtering and ordering at the repository level
/// - User-scoped: All operations are implicitly scoped to the current user
///
/// ## Usage
/// ```dart
/// final result = await contractRepository.getActiveContracts();
/// result.fold(
///   (failure) => handleError(failure),
///   (contracts) => displayContracts(contracts),
/// );
/// ```
abstract class ContractRepository {
  /// Get all contracts for the current user.
  ///
  /// Returns all contracts regardless of status.
  Future<Either<Failure, List<Contract>>> getAllContracts();

  /// Get contracts filtered by status.
  ///
  /// [status] - Filter contracts by their current status
  Future<Either<Failure, List<Contract>>> getContractsByStatus(
    ContractStatus status,
  );

  /// Get contracts filtered by type.
  ///
  /// [type] - Filter contracts by their type (reducing, growing, fixed)
  Future<Either<Failure, List<Contract>>> getContractsByType(ContractType type);

  /// Get only active contracts.
  ///
  /// This is an optimized read for the most common use case.
  Future<Either<Failure, List<Contract>>> getActiveContracts();

  /// Get a single contract by ID.
  ///
  /// [contractId] - The unique identifier of the contract
  /// Returns [NotFoundFailure] if the contract doesn't exist.
  Future<Either<Failure, Contract>> getContractById(String contractId);

  /// Create a new contract.
  ///
  /// [contract] - The contract to create
  /// Returns the ID of the created contract.
  Future<Either<Failure, String>> createContract(Contract contract);

  /// Update an existing contract.
  ///
  /// [contract] - The contract with updated fields
  /// The contract must have a valid ID.
  Future<Either<Failure, void>> updateContract(Contract contract);

  /// Delete a contract.
  ///
  /// [contractId] - The unique identifier of the contract to delete
  /// Note: Consider using soft delete (status change) instead.
  Future<Either<Failure, void>> deleteContract(String contractId);

  /// Close a contract (soft delete).
  ///
  /// [contractId] - The unique identifier of the contract
  /// Sets the contract status to 'closed' rather than deleting.
  Future<Either<Failure, void>> closeContract(String contractId);

  /// Pause a contract.
  ///
  /// [contractId] - The unique identifier of the contract
  /// Sets the contract status to 'paused'.
  Future<Either<Failure, void>> pauseContract(String contractId);

  /// Resume a paused contract.
  ///
  /// [contractId] - The unique identifier of the contract
  /// Sets the contract status back to 'active'.
  Future<Either<Failure, void>> resumeContract(String contractId);

  /// Stream all contracts for real-time updates.
  ///
  /// Returns a stream that emits whenever contracts change.
  Stream<Either<Failure, List<Contract>>> watchAllContracts();

  /// Stream active contracts for real-time updates.
  ///
  /// Returns a stream that emits whenever active contracts change.
  Stream<Either<Failure, List<Contract>>> watchActiveContracts();

  /// Stream a single contract for real-time updates.
  ///
  /// [contractId] - The unique identifier of the contract
  Stream<Either<Failure, Contract>> watchContract(String contractId);

  /// Batch update multiple contracts.
  ///
  /// [contracts] - List of contracts to update
  /// All operations are performed atomically.
  Future<Either<Failure, void>> batchUpdateContracts(List<Contract> contracts);

  /// Get contracts that will end within the specified days.
  ///
  /// [days] - Number of days to look ahead
  /// Useful for expiry reminders.
  Future<Either<Failure, List<Contract>>> getContractsEndingSoon(int days);
}
