import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/repositories/contract_repository.dart';
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

    result.fold(
      (failure) => emit(ContractDetailError(message: failure.message)),
      (contract) => emit(ContractDetailLoaded(contract: contract)),
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
              (contract) {
                final currentState = state;
                if (currentState is ContractDetailLoaded) {
                  emit(
                    currentState.copyWith(
                      contract: contract,
                      isUpdating: false,
                    ),
                  );
                } else {
                  emit(ContractDetailLoaded(contract: contract));
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
