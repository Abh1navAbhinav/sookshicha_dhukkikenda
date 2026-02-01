import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_status.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/repositories/contract_repository.dart';
import '../../../domain/usecases/loan_amortization_engine.dart';
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
        final caughtUpContract = _catchUpContract(contract);

        if (caughtUpContract != contract) {
          // Sync with repository if state changed
          await _contractRepository.updateContract(caughtUpContract);
          _emitLoaded(caughtUpContract);
        } else {
          _emitLoaded(contract);
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
                final caughtUpContract = _catchUpContract(contract);

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
                      loanDetails: _generateLoanSnapshot(caughtUpContract),
                    ),
                  );
                } else {
                  _emitLoaded(caughtUpContract);
                }
              },
            );
          },
          onError: (error) {
            emit(ContractDetailError(message: 'Stream error: $error'));
          },
        );
  }

  Contract _catchUpContract(Contract contract) {
    final now = DateTime.now();
    const engine = MonthlyExecutionEngine();
    return engine.catchUpContract(contract, now.month, now.year);
  }

  void _emitLoaded(Contract contract) {
    emit(
      ContractDetailLoaded(
        contract: contract,
        loanDetails: _generateLoanSnapshot(contract),
      ),
    );
  }

  LoanSnapshotUIModel? _generateLoanSnapshot(Contract contract) {
    if (contract.type != ContractType.reducing) return null;
    final metadata = contract.reducingMetadata;
    if (metadata == null) return null;

    const engine = LoanAmortizationEngine();

    // Generate the full schedule based on original parameters
    final summary = engine.generateAmortizationSchedule(
      principal: metadata.principalAmount,
      annualInterestRate: metadata.interestRatePercent,
      tenureMonths: metadata.tenureMonths,
      emi: metadata.emiAmount,
      startDate: contract.startDate,
    );

    final monthsElapsed = contract.elapsedMonths;
    final schedule = summary.schedule;

    // Determine the relevant schedule entries
    // Index in schedule is (monthNumber - 1)

    // Current status (what has been paid so far)
    final int paidIndex = monthsElapsed - 1;
    final paidEntry = (paidIndex >= 0 && paidIndex < schedule.length)
        ? schedule[paidIndex]
        : null;

    // Next month's details (what comes next)
    final int nextIndex = monthsElapsed;
    final nextEntry = (nextIndex >= 0 && nextIndex < schedule.length)
        ? schedule[nextIndex]
        : null;

    // Extract values
    double principalPaid;
    double interestPaid;
    double remainingPrincipal;
    // double remainingBalance; // Not used directly, we derive from princ + int

    if (paidEntry != null) {
      principalPaid = paidEntry.cumulativePrincipalPaid;
      interestPaid = paidEntry.cumulativeInterestPaid;
      remainingPrincipal = paidEntry.remainingBalance;
    } else if (monthsElapsed <= 0) {
      // Start of loan
      principalPaid = 0;
      interestPaid = 0;
      remainingPrincipal = metadata.principalAmount;
    } else {
      // Loan finished (schedule exhausted)
      principalPaid = summary.totalAmountPayable - summary.totalInterestPayable;
      interestPaid = summary.totalInterestPayable;
      remainingPrincipal = 0;
    }

    // Monthly breakdown for display
    double monthlyInterest;
    double monthlyPrincipal;

    if (nextEntry != null) {
      monthlyInterest = nextEntry.interestPortion;
      monthlyPrincipal = nextEntry.principalPortion;
    } else {
      // Loan closed or ended
      monthlyInterest = 0;
      monthlyPrincipal = 0;
    }

    final totalInterest = summary.totalInterestPayable;
    final totalPayable = summary.totalAmountPayable;

    // Remaining interest = Total Interest - Interest Paid
    final remainingInterest = totalInterest - interestPaid;

    // Remaining Balance = Total Payable - Total Paid
    // Or = Remaining Principal + Remaining Interest
    final remainingBalance = remainingPrincipal + remainingInterest;

    return LoanSnapshotUIModel(
      monthlyInterest: monthlyInterest,
      monthlyPrincipal: monthlyPrincipal,
      totalInterestFullTenure: totalInterest,
      totalPayableFullTenure: totalPayable,
      principalPaidTillDate: principalPaid,
      interestPaidTillDate: interestPaid,
      remainingPrincipal: remainingPrincipal,
      remainingInterest: remainingInterest,
      remainingBalance: remainingBalance,
      progressPercent: (principalPaid / metadata.principalAmount) * 100,
      originalPrincipal: metadata.principalAmount,
      interestRate: metadata.interestRatePercent,
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

  /// Toggle dashboard visibility
  Future<void> toggleShowOnDashboard() async {
    final currentState = state;
    if (currentState is! ContractDetailLoaded) return;

    final contract = currentState.contract;
    final updatedContract = contract.copyWith(
      showOnDashboard: !contract.showOnDashboard,
    );

    emit(currentState.copyWith(isUpdating: true));

    final result = await _contractRepository.updateContract(updatedContract);

    result.fold(
      (failure) => emit(currentState.copyWith(isUpdating: false)),
      (_) => loadContract(contract.id),
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
