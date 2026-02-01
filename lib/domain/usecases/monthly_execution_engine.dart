import 'dart:math';

import '../entities/contract/contract.dart';
import '../entities/contract/contract_status.dart';
import '../entities/contract/contract_type.dart';
import '../entities/snapshot/monthly_snapshot.dart';

/// A pure, deterministic monthly execution engine for financial contracts.
///
/// This engine processes all active contracts for a given month and generates
/// comprehensive financial snapshots. It operates automatically without any
/// manual monthly input.
///
/// ## Key Features (Refactored)
/// 1. **Full Precision**: Internal calculations use full double precision to prevent drift.
/// 2. **Deterministic**: Produces identical results for identical inputs.
/// 3. **Single Source of Truth**: Aligns with LoanAmortizationEngine logic.
///
class MonthlyExecutionEngine {
  const MonthlyExecutionEngine();

  /// Precision for monetary calculations (display/final output only)
  static const int _decimalPlaces = 2;

  /// Tolerance for zero comparisons
  static const double _zeroTolerance = 0.01;

  /// Executes monthly calculations for all provided contracts.
  MonthlySnapshot executeMonth({
    required List<Contract> contracts,
    required int month,
    required int year,
    double totalIncome = 0.0,
    bool includeBreakdown = true,
  }) {
    // Validate inputs
    _validateMonthYear(month, year);

    // Step 1: Filter active contracts applicable to this month
    final targetDate = DateTime(year, month);
    final activeContracts = _filterActiveContractsForMonth(
      contracts,
      targetDate,
    );

    // If no active contracts, return empty snapshot
    if (activeContracts.isEmpty) {
      return MonthlySnapshot.empty(
        month: month,
        year: year,
        totalIncome: totalIncome,
      );
    }

    // Step 2: Process each contract by type
    final contributions = <ContractContribution>[];
    double reducingOutflow = 0.0;
    double growingOutflow = 0.0;
    double fixedOutflow = 0.0;
    double totalWealth = 0.0;
    double totalDebt = 0.0;

    for (final contract in activeContracts) {
      final contribution = _processContract(contract, targetDate);

      switch (contract.type) {
        case ContractType.reducing:
          reducingOutflow += contribution.amount;

          // Calculate total remaining payable (Principal + Interest)
          if (contribution.newBalance != null) {
            final remainingMonths = calculateRemainingTenure(
              balance: contribution.newBalance!,
              annualInterestRate:
                  contract.reducingMetadata?.interestRatePercent ?? 0,
              emi: contract.reducingMetadata?.emiAmount ?? 0,
            );
            totalDebt +=
                remainingMonths * (contract.reducingMetadata?.emiAmount ?? 0);
          }
          break;

        case ContractType.growing:
          growingOutflow += contribution.amount;
          // Show Accumulated Wealth
          totalWealth += contract.growingMetadata?.totalInvested ?? 0.0;
          break;

        case ContractType.fixed:
          fixedOutflow += contribution.amount;
          if (contract.fixedMetadata?.isLiability == false) {
            // Asset
            totalWealth +=
                contract.fixedMetadata?.coverageAmount ??
                contract.monthlyAmount;
          } else {
            // Liability
            totalDebt +=
                contract.fixedMetadata?.coverageAmount ??
                contract.monthlyAmount;
          }
          break;
      }

      if (includeBreakdown) {
        contributions.add(contribution);
      }
    }

    // Step 3: Round final values (Applying rounding ONLY at display/snapshot level)
    reducingOutflow = _round(reducingOutflow);
    growingOutflow = _round(growingOutflow);
    fixedOutflow = _round(fixedOutflow);
    totalWealth = _round(totalWealth);
    totalDebt = _round(totalDebt);

    final mandatoryOutflow = _round(
      reducingOutflow + growingOutflow + fixedOutflow,
    );

    // Step 4: Build and return snapshot
    return MonthlySnapshot(
      month: month,
      year: year,
      totalIncome: totalIncome,
      mandatoryOutflow: mandatoryOutflow,
      activeContractCount: activeContracts.length,
      reducingOutflow: reducingOutflow,
      growingOutflow: growingOutflow,
      fixedOutflow: fixedOutflow,
      totalWealth: totalWealth,
      totalDebt: totalDebt,
      contractBreakdown: includeBreakdown ? contributions : null,
      generatedAt: DateTime.now(),
    );
  }

  /// Catches up a contract's state from its start date to the beginning of the target month.
  Contract catchUpContract(Contract contract, int targetMonth, int targetYear) {
    if (contract.status != ContractStatus.active) return contract;

    // Calculate how many months should have been processed by the target month
    final targetDate = DateTime(targetYear, targetMonth, 1);
    final startDate = DateTime(
      contract.startDate.year,
      contract.startDate.month,
      1,
    );

    // If target date is before start date, nothing to catch up
    if (targetDate.isBefore(startDate)) return contract;

    final totalMonthsExpected =
        (targetDate.year - startDate.year) * 12 +
        (targetDate.month - startDate.month);

    // See how many months have already been applied
    int monthsAlreadyApplied = 0;
    if (contract.type == ContractType.reducing) {
      monthsAlreadyApplied = contract.reducingMetadata?.paidInstallments ?? 0;
    } else if (contract.type == ContractType.growing) {
      monthsAlreadyApplied = contract.growingMetadata?.paidMonths ?? 0;
    }

    // Only apply the difference
    int monthsToApply = totalMonthsExpected - monthsAlreadyApplied;
    if (monthsToApply <= 0) return contract;

    var currentContract = contract;
    // We start processing from the month AFTER the last applied month
    var processDate = DateTime(
      startDate.year,
      startDate.month + monthsAlreadyApplied,
    );

    for (int i = 0; i < monthsToApply; i++) {
      final advanced = _advanceContractStates([currentContract], processDate);

      if (advanced.isEmpty) break;
      currentContract = advanced.first;

      // Move to next month
      processDate = DateTime(processDate.year, processDate.month + 1);

      // Safety break
      if (processDate.year > 2100) break;
    }

    return currentContract;
  }

  /// Calculates the projected remaining months for a reducing loan.
  int calculateRemainingTenure({
    required double balance,
    required double annualInterestRate,
    required double emi,
  }) {
    if (balance <= _zeroTolerance) return 0;
    if (emi <= _zeroTolerance) return 999; // Error case

    final monthlyRate = annualInterestRate / 12 / 100;

    // Zero interest case
    if (monthlyRate <= 0) {
      return (balance / emi).ceil();
    }

    // If interest is more than EMI, it will never end
    if (balance * monthlyRate >= emi) return 999;

    // Formula for remaining months
    try {
      final numerator = log(1 - (balance * monthlyRate / emi));
      final denominator = log(1 + monthlyRate);
      return (-(numerator / denominator)).ceil();
    } catch (_) {
      // Fallback to simple simulation if log fails
      int months = 0;
      double currentBalance = balance;
      while (currentBalance > _zeroTolerance && months < 1200) {
        final interest = currentBalance * monthlyRate;
        final principal = emi - interest;
        currentBalance -= principal;
        months++;
      }
      return months;
    }
  }

  /// Calculates the annual interest rate for a loan.
  double calculateAnnualInterestRate({
    required double principal,
    required double emi,
    required int tenureMonths,
  }) {
    if (principal <= 0 || emi <= 0 || tenureMonths <= 0) return 0;
    if (emi * tenureMonths <= principal) return 0; // No interest

    double low = 0;
    double high = 500; // Increased to support high-interest short-term loans
    double mid = 0;

    for (int i = 0; i < 40; i++) {
      // 40 iterations for high precision
      mid = (low + high) / 2;
      final calculatedEmi = calculateEmi(
        principal: principal,
        annualInterestRate: mid,
        tenureMonths: tenureMonths,
      );

      if (calculatedEmi > emi) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return _roundTo(mid, 2);
  }

  /// Calculates EMI for a loan.
  double calculateEmi({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (annualInterestRate <= 0) return principal / tenureMonths;

    final monthlyRate = annualInterestRate / 12 / 100;
    final factor = pow(1 + monthlyRate, tenureMonths);
    return principal * monthlyRate * factor / (factor - 1);
  }

  double _roundTo(double value, int places) {
    final mod = pow(10, places);
    return (value * mod).round() / mod;
  }

  /// Generates a multi-month projection with updated contract states.
  MonthlyProjection generateProjection({
    required List<Contract> contracts,
    required int startMonth,
    required int startYear,
    required int monthCount,
    double monthlyIncome = 0.0,
  }) {
    _validateMonthYear(startMonth, startYear);
    if (monthCount <= 0) {
      throw ArgumentError('monthCount must be positive. Got: $monthCount');
    }

    final snapshots = <MonthlySnapshot>[];
    var currentContracts = contracts.toList(); // Copy to avoid mutation

    int currentMonth = startMonth;
    int currentYear = startYear;

    for (int i = 0; i < monthCount; i++) {
      // Generate snapshot for current month
      final snapshot = executeMonth(
        contracts: currentContracts,
        month: currentMonth,
        year: currentYear,
        totalIncome: monthlyIncome,
        includeBreakdown: true,
      );
      snapshots.add(snapshot);

      // Update contract states for next month
      currentContracts = _advanceContractStates(
        currentContracts,
        DateTime(currentYear, currentMonth),
      );

      // Move to next month
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return MonthlyProjection(
      snapshots: snapshots,
      finalContractStates: currentContracts,
      projectedFromMonth: startMonth,
      projectedFromYear: startYear,
      projectedToMonth: currentMonth == 1 ? 12 : currentMonth - 1,
      projectedToYear: currentMonth == 1 ? currentYear - 1 : currentYear,
    );
  }

  /// Calculates total outflow for a specific contract type over N months.
  double calculateTypeOutflow({
    required List<Contract> contracts,
    required ContractType type,
    required int startMonth,
    required int startYear,
    required int monthCount,
  }) {
    final projection = generateProjection(
      contracts: contracts,
      startMonth: startMonth,
      startYear: startYear,
      monthCount: monthCount,
    );

    double total = 0.0;
    for (final snapshot in projection.snapshots) {
      switch (type) {
        case ContractType.reducing:
          total += snapshot.reducingOutflow;
          break;
        case ContractType.growing:
          total += snapshot.growingOutflow;
          break;
        case ContractType.fixed:
          total += snapshot.fixedOutflow;
          break;
      }
    }
    return _round(total);
  }

  // ============== Private Helper Methods ==============

  /// Filters contracts that are active and applicable for the given month.
  List<Contract> _filterActiveContractsForMonth(
    List<Contract> contracts,
    DateTime targetDate,
  ) {
    return contracts.where((contract) {
      // Must be active
      if (contract.status != ContractStatus.active) return false;

      // Must have started by the target month
      final startOfTargetMonth = DateTime(targetDate.year, targetDate.month, 1);
      final contractStartMonth = DateTime(
        contract.startDate.year,
        contract.startDate.month,
        1,
      );

      if (contractStartMonth.isAfter(startOfTargetMonth)) return false;

      // If has end date, must not have ended before target month
      if (contract.endDate != null) {
        final contractEndMonth = DateTime(
          contract.endDate!.year,
          contract.endDate!.month,
          1,
        );
        if (startOfTargetMonth.isAfter(contractEndMonth)) return false;
      }

      return true;
    }).toList();
  }

  /// Processes a single contract and returns its contribution.
  ContractContribution _processContract(
    Contract contract,
    DateTime targetDate,
  ) {
    switch (contract.type) {
      case ContractType.reducing:
        return _processReducingContract(contract);
      case ContractType.growing:
        return _processGrowingContract(contract);
      case ContractType.fixed:
        return _processFixedContract(contract);
    }
  }

  /// Processes a reducing contract (loan/EMI).
  ContractContribution _processReducingContract(Contract contract) {
    final metadata = contract.reducingMetadata!;
    final emi = metadata.emiAmount;
    final balance = metadata.remainingBalance;
    final monthlyRate = metadata.interestRatePercent / 12 / 100;

    // Calculate interest and principal for this month (Full Precision)
    final interestPortion = balance * monthlyRate;
    final principalPortion = emi - interestPortion;
    // Calculate new balance with full precision but clamp to zero
    final newBalance = max(0.0, balance - principalPortion);

    return ContractContribution(
      contractId: contract.id,
      contractName: contract.name,
      contractType: contract.type.value,
      amount: emi,
      principalPortion: principalPortion,
      interestPortion: interestPortion,
      newBalance: newBalance,
    );
  }

  /// Processes a growing contract (investment/SIP).
  ContractContribution _processGrowingContract(Contract contract) {
    final metadata = contract.growingMetadata!;
    final monthlyAmount = contract.monthlyAmount;
    final currentInvested = metadata.totalInvested;
    // Full Precision
    final newInvestedTotal = currentInvested + monthlyAmount;

    return ContractContribution(
      contractId: contract.id,
      contractName: contract.name,
      contractType: contract.type.value,
      amount: monthlyAmount,
      newInvestedTotal: newInvestedTotal,
    );
  }

  /// Processes a fixed contract (subscription/insurance).
  ContractContribution _processFixedContract(Contract contract) {
    // Fixed contracts use monthlyAmount directly
    return ContractContribution(
      contractId: contract.id,
      contractName: contract.name,
      contractType: contract.type.value,
      amount: contract.monthlyAmount,
    );
  }

  /// Advances contract states by one month (for projections).
  List<Contract> _advanceContractStates(
    List<Contract> contracts,
    DateTime currentMonth,
  ) {
    return contracts.map((contract) {
      // Only update active contracts
      if (contract.status != ContractStatus.active) return contract;

      // Check if contract is applicable for this month
      final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
      final contractStart = DateTime(
        contract.startDate.year,
        contract.startDate.month,
        1,
      );
      if (contractStart.isAfter(startOfMonth)) return contract;

      switch (contract.type) {
        case ContractType.reducing:
          return _advanceReducingContract(contract);
        case ContractType.growing:
          return _advanceGrowingContract(contract);
        case ContractType.fixed:
          return contract; // No state change for fixed
      }
    }).toList();
  }

  /// Advances a reducing contract by one month.
  Contract _advanceReducingContract(Contract contract) {
    final metadata = contract.reducingMetadata!;
    final balance = metadata.remainingBalance;

    // If already paid off, mark as closed
    if (balance <= _zeroTolerance) {
      return contract.copyWith(status: ContractStatus.closed);
    }

    final monthlyRate = metadata.interestRatePercent / 12 / 100;
    // Full Precision
    final interest = balance * monthlyRate;
    final principal = metadata.emiAmount - interest;

    // New balance logic (Full Precision)
    var newBalance = max(0.0, balance - principal);
    if (newBalance < _zeroTolerance) newBalance = 0.0;

    final newPaidInstallments = metadata.paidInstallments + 1;

    // Check if loan is now fully paid
    final newStatus = newBalance <= _zeroTolerance
        ? ContractStatus.closed
        : contract.status;

    return contract.copyWith(
      status: newStatus,
      metadata: metadata.copyWith(
        remainingBalance: newBalance,
        paidInstallments: newPaidInstallments,
      ),
    );
  }

  /// Advances a growing contract by one month.
  Contract _advanceGrowingContract(Contract contract) {
    final metadata = contract.growingMetadata!;
    // Full Precision
    final newInvested = metadata.totalInvested + contract.monthlyAmount;
    final newCurrentValue = metadata.currentValue + contract.monthlyAmount;
    final newPaidMonths = metadata.paidMonths + 1;

    return contract.copyWith(
      metadata: metadata.copyWith(
        totalInvested: newInvested,
        currentValue: newCurrentValue,
        paidMonths: newPaidMonths,
      ),
    );
  }

  /// Validates month and year parameters.
  void _validateMonthYear(int month, int year) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12. Got: $month');
    }
    if (year < 1900 || year > 2100) {
      throw ArgumentError('Year must be between 1900 and 2100. Got: $year');
    }
  }

  /// Rounds to standard decimal places (For Display Only).
  double _round(double value) {
    final multiplier = pow(10, _decimalPlaces);
    return (value * multiplier).round() / multiplier;
  }
}

/// Represents the result of a multi-month projection.
final class MonthlyProjection {
  const MonthlyProjection({
    required this.snapshots,
    required this.finalContractStates,
    required this.projectedFromMonth,
    required this.projectedFromYear,
    required this.projectedToMonth,
    required this.projectedToYear,
  });

  /// All generated monthly snapshots in chronological order
  final List<MonthlySnapshot> snapshots;

  /// Contract states after the last projected month
  final List<Contract> finalContractStates;

  /// Starting month of projection
  final int projectedFromMonth;

  /// Starting year of projection
  final int projectedFromYear;

  /// Ending month of projection
  final int projectedToMonth;

  /// Ending year of projection
  final int projectedToYear;

  // ============== Computed Properties ==============

  /// Total mandatory outflow across all projected months
  double get totalMandatoryOutflow =>
      snapshots.fold(0.0, (sum, s) => sum + s.mandatoryOutflow);

  /// Total income across all projected months
  double get totalIncome =>
      snapshots.fold(0.0, (sum, s) => sum + s.totalIncome);

  /// Total free balance across all projected months
  double get totalFreeBalance => totalIncome - totalMandatoryOutflow;

  /// Average monthly outflow
  double get averageMonthlyOutflow =>
      snapshots.isNotEmpty ? totalMandatoryOutflow / snapshots.length : 0.0;

  /// Number of months projected
  int get monthCount => snapshots.length;

  /// First snapshot
  MonthlySnapshot? get firstSnapshot =>
      snapshots.isNotEmpty ? snapshots.first : null;

  /// Last snapshot
  MonthlySnapshot? get lastSnapshot =>
      snapshots.isNotEmpty ? snapshots.last : null;
}
