import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/contract/contract_status.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/repositories/contract_repository.dart';
import 'contracts_state.dart';

/// Contracts Cubit
///
/// Manages contracts list with real-time updates.
/// Supports filtering and search operations.
///
/// ## Design Principles
/// - Streams real-time updates from repository
/// - All filtering logic stays in state
/// - UI only renders, never transforms data
@injectable
class ContractsCubit extends Cubit<ContractsState> {
  ContractsCubit({required ContractRepository contractRepository})
    : _contractRepository = contractRepository,
      super(const ContractsInitial());

  final ContractRepository _contractRepository;
  StreamSubscription<dynamic>? _contractsSubscription;

  /// Load all contracts
  Future<void> loadContracts() async {
    emit(const ContractsLoading());

    final result = await _contractRepository.getAllContracts();

    result.fold(
      (failure) => emit(ContractsError(message: failure.message)),
      (contracts) => emit(ContractsLoaded(allContracts: contracts)),
    );
  }

  /// Subscribe to real-time contract updates
  void watchContracts() {
    emit(const ContractsLoading());

    _contractsSubscription?.cancel();
    _contractsSubscription = _contractRepository.watchAllContracts().listen(
      (result) {
        result.fold(
          (failure) => emit(ContractsError(message: failure.message)),
          (contracts) {
            final currentState = state;
            if (currentState is ContractsLoaded) {
              // Preserve filters when updating data
              emit(currentState.copyWith(allContracts: contracts));
            } else {
              emit(ContractsLoaded(allContracts: contracts));
            }
          },
        );
      },
      onError: (error) {
        emit(ContractsError(message: 'Stream error: $error'));
      },
    );
  }

  /// Filter by contract type
  void filterByType(ContractType? type) {
    final currentState = state;
    if (currentState is ContractsLoaded) {
      if (type == null) {
        emit(currentState.copyWith(clearTypeFilter: true));
      } else {
        emit(currentState.copyWith(filterType: type));
      }
    }
  }

  /// Filter by contract status
  void filterByStatus(ContractStatus? status) {
    final currentState = state;
    if (currentState is ContractsLoaded) {
      if (status == null) {
        emit(currentState.copyWith(clearStatusFilter: true));
      } else {
        emit(currentState.copyWith(filterStatus: status));
      }
    }
  }

  /// Search contracts
  void search(String query) {
    final currentState = state;
    if (currentState is ContractsLoaded) {
      if (query.isEmpty) {
        emit(currentState.copyWith(clearSearch: true));
      } else {
        emit(currentState.copyWith(searchQuery: query));
      }
    }
  }

  /// Clear all filters
  void clearFilters() {
    final currentState = state;
    if (currentState is ContractsLoaded) {
      emit(
        currentState.copyWith(
          clearTypeFilter: true,
          clearStatusFilter: true,
          clearSearch: true,
        ),
      );
    }
  }

  /// Refresh contracts
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is ContractsLoaded) {
      // Keep the current state visible during refresh
      final result = await _contractRepository.getAllContracts();
      result.fold(
        (failure) => emit(ContractsError(message: failure.message)),
        (contracts) => emit(currentState.copyWith(allContracts: contracts)),
      );
    } else {
      await loadContracts();
    }
  }

  /// Delete a contract
  Future<void> deleteContract(String contractId) async {
    final result = await _contractRepository.deleteContract(contractId);
    if (result.isLeft()) {
      result.fold(
        (failure) => emit(ContractsError(message: failure.message)),
        (_) => null,
      );
    }
  }

  @override
  Future<void> close() {
    _contractsSubscription?.cancel();
    return super.close();
  }
}
