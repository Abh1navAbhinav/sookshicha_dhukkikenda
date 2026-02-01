import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/contract/contract_status.dart';
import '../../../domain/repositories/contract_repository.dart';
import '../../../domain/usecases/monthly_execution_engine.dart';
import 'contract_detail_state.dart';

/// Contract Detail Cubit
///
/// Manages a single contract's detail view with real-time updates.
/// Supports pause, resume, and close operations.
///
/// ## Design Principles
/// - One cubit per detail screen instance
/// - Streams the contract for real-time updates
/// - All mutations go through repository
@injectable
class ContractDetailCubit extends Cubit<ContractDetailState> {
  ContractDetailCubit({required ContractRepository contractRepository})
    : _contractRepository = contractRepository,
      super(const ContractDetailInitial());

  final ContractRepository _contractRepository;
  StreamSubscription<dynamic>? _contractSubscription;

  /// Load a contract by ID
  Future<void> loadContract(String contractId) async {
    emit(const ContractDetailLoading());

    final result = await _contractRepository.getContractById(contractId);

    await result.fold(
      (failure) async => emit(ContractDetailError(message: failure.message)),
      (contract) async {
        // Automatically catch up the contract to the current month
        final now = DateTime.now();
        const engine = MonthlyExecutionEngine();
        final caughtUpContract = engine.catchUpContract(
          contract,
          now.month,
          now.year,
        );

        if (caughtUpContract != contract) {
          // Sync with repository if state changed
          await _contractRepository.updateContract(caughtUpContract);
          emit(ContractDetailLoaded(contract: caughtUpContract));
        } else {
          emit(ContractDetailLoaded(contract: contract));
        }
      },
    );
  }

  /// Watch a contract for real-time updates
  void watchContract(String contractId) {
    emit(const ContractDetailLoading());

    _contractSubscription?.cancel();
    _contractSubscription = _contractRepository
        .watchContract(contractId)
        .listen(
          (result) {
            result.fold(
              (failure) => emit(ContractDetailError(message: failure.message)),
              (contract) async {
                final now = DateTime.now();
                const engine = MonthlyExecutionEngine();
                final caughtUpContract = engine.catchUpContract(
                  contract,
                  now.month,
                  now.year,
                );

                if (caughtUpContract != contract) {
                  // If changed, trigger update but don't wait to emit
                  _contractRepository.updateContract(caughtUpContract);
                }

                final currentState = state;
                if (currentState is ContractDetailLoaded) {
                  emit(
                    currentState.copyWith(
                      contract: caughtUpContract,
                      isUpdating: false,
                    ),
                  );
                } else {
                  emit(ContractDetailLoaded(contract: caughtUpContract));
                }
              },
            );
          },
          onError: (error) {
            emit(ContractDetailError(message: 'Stream error: $error'));
          },
        );
  }

  /// Pause the contract
  Future<void> pauseContract() async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await _contractRepository.pauseContract(
      currentState.contract.id,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
        // Could emit a separate error state for snackbar
      },
      (_) {
        // Reload to get updated contract
        loadContract(currentState.contract.id);
      },
    );
  }

  /// Resume a paused contract
  Future<void> resumeContract() async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await _contractRepository.resumeContract(
      currentState.contract.id,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
      },
      (_) {
        loadContract(currentState.contract.id);
      },
    );
  }

  /// Process a manual prepayment for a loan
  Future<void> makePrepayment(double amount) async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    final contract = currentState.contract;
    final metadata = contract.reducingMetadata;
    if (metadata == null) return;

    emit(currentState.copyWith(isUpdating: true));

    final newBalance = (metadata.remainingBalance - amount).clamp(
      0.0,
      double.infinity,
    );
    final newPrepayments = metadata.prepaymentsMade + amount;

    final updatedMetadata = metadata.copyWith(
      remainingBalance: newBalance,
      prepaymentsMade: newPrepayments,
    );

    var updatedContract = contract.copyWith(metadata: updatedMetadata);

    // Auto-close if paid off
    if (newBalance <= 0) {
      updatedContract = updatedContract.copyWith(status: ContractStatus.closed);
    }

    final result = await _contractRepository.updateContract(updatedContract);

    result.fold((failure) => emit(currentState.copyWith(isUpdating: false)), (
      _,
    ) {
      if (newBalance <= 0) {
        emit(
          ContractDetailActionCompleted(
            action: ContractAction.closed,
            contract: updatedContract,
          ),
        );
      } else {
        loadContract(contract.id);
      }
    });
  }

  /// Close the contract
  Future<void> closeContract() async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await _contractRepository.closeContract(
      currentState.contract.id,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
      },
      (_) {
        emit(
          ContractDetailActionCompleted(
            action: ContractAction.closed,
            contract: currentState.contract,
          ),
        );
      },
    );
  }

  /// Permanently delete the contract
  Future<void> deleteContract() async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await _contractRepository.deleteContract(
      currentState.contract.id,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
      },
      (_) {
        emit(
          ContractDetailActionCompleted(
            action: ContractAction.deleted,
            contract: currentState.contract,
          ),
        );
      },
    );
  }

  /// Refresh contract data
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is ContractDetailLoaded) {
      await loadContract(currentState.contract.id);
    }
  }

  @override
  Future<void> close() {
    _contractSubscription?.cancel();
    return super.close();
  }
}
