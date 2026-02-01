import 'dart:math';

import '../entities/loan/loan_barrel.dart';

/// A pure, deterministic reducing-balance loan amortization engine.
///
/// This engine calculates the complete amortization schedule for a loan
/// using the reducing balance method.
///
/// ## Key Features (Refactored)
/// 1. **Full Precision**: Calculations use full double precision without intermediate rounding
///    to prevent drift over long tenures.
/// 2. **Guaranteed Closure**: The final month (tenure) allows for a "balloon" or adjusted payment
///    to ensure the loan balance hits exactly 0.0.
/// 3. **Single Source of Truth**: The generate schedule is the definitive timeline.
///
class LoanAmortizationEngine {
  const LoanAmortizationEngine();

  /// Number of decimal places for display rounding only
  static const int _decimalPlaces = 2;

  /// Tolerance for considering a balance as zero
  static const double _zeroTolerance = 0.01;

  /// Generates a complete amortization schedule for the given loan parameters.
  ///
  /// Uses full precision arithmetic and forces loan closure on the last month of [tenureMonths].
  LoanSummary generateAmortizationSchedule({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required double emi,
    required DateTime startDate,
  }) {
    // Validate inputs
    _validateInputs(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      emi: emi,
    );

    final monthlyInterestRate = annualInterestRate / 12 / 100;
    final schedule = <AmortizationEntry>[];

    double remainingBalance = principal;
    double cumulativePrincipalPaid = 0;
    double cumulativeInterestPaid = 0;

    // Use a fixed loop based on tenure to ensure we respect the contract duration
    for (int monthNumber = 1; monthNumber <= tenureMonths; monthNumber++) {
      // Calculate payment date
      final paymentDate = _addMonths(startDate, monthNumber - 1);

      // Stop if balance is already cleared (e.g. if EMI is high)
      if (remainingBalance <= _zeroTolerance) {
        break;
      }

      // Calculate interest (Full Precision)
      final interestForMonth = remainingBalance * monthlyInterestRate;

      double principalForMonth;
      double actualEmi;

      final principalIfFullEmi = emi - interestForMonth;

      // Check for clearance:
      // 1. If this is the LAST month of tenure, we MUST clear the balance.
      // 2. If the remaining balance is small enough to be cleared by standard EMI.
      final isLastMonth = monthNumber == tenureMonths;
      final canClearEarly =
          remainingBalance <= principalIfFullEmi + _zeroTolerance;

      if (isLastMonth || canClearEarly) {
        // Force clearance
        principalForMonth = remainingBalance;
        actualEmi = principalForMonth + interestForMonth;
      } else {
        // Regular payment
        principalForMonth = principalIfFullEmi;
        actualEmi = emi;
      }

      // Update state (Full Precision)
      remainingBalance -= principalForMonth;

      // Clamp to zero to avoid negative zero or epsilon errors
      if (remainingBalance < _zeroTolerance) remainingBalance = 0.0;

      cumulativePrincipalPaid += principalForMonth;
      cumulativeInterestPaid += interestForMonth;

      schedule.add(
        AmortizationEntry(
          monthNumber: monthNumber,
          paymentDate: paymentDate,
          emiPaid:
              actualEmi, // This may differ from standard EMI on the last month
          principalPortion: principalForMonth,
          interestPortion: interestForMonth,
          remainingBalance: remainingBalance,
          cumulativePrincipalPaid: cumulativePrincipalPaid,
          cumulativeInterestPaid: cumulativeInterestPaid,
        ),
      );
    }

    // Return the summary with full precision values.
    // The consumer (UI) should handle rounding for display.
    return LoanSummary(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      emi: emi,
      startDate: startDate,
      schedule: schedule,
      totalAmountPayable: cumulativePrincipalPaid + cumulativeInterestPaid,
      totalInterestPayable: cumulativeInterestPaid,
      expectedClosureDate: schedule.isNotEmpty
          ? schedule.last.paymentDate
          : startDate,
    );
  }

  /// Calculates the standard EMI for given loan parameters.
  ///
  /// Returns the calculated EMI (full precision).
  static double calculateEmi({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0) {
      throw ArgumentError('Principal must be positive');
    }
    if (tenureMonths <= 0) {
      throw ArgumentError('Tenure must be positive');
    }

    // Handle zero interest rate
    if (annualInterestRate <= 0) {
      return principal / tenureMonths;
    }

    final r = annualInterestRate / 12 / 100; // Monthly interest rate
    final n = tenureMonths;

    // EMI = P × r × (1 + r)^n / [(1 + r)^n - 1]
    final onePlusRPowerN = pow(1 + r, n);
    final emi = principal * r * onePlusRPowerN / (onePlusRPowerN - 1);

    return emi.toDouble();
  }

  /// Validates all input parameters.
  void _validateInputs({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required double emi,
  }) {
    if (principal <= 0) {
      throw ArgumentError(
        'Principal must be a positive number. Got: $principal',
      );
    }
    if (annualInterestRate < 0) {
      throw ArgumentError(
        'Annual interest rate cannot be negative. Got: $annualInterestRate',
      );
    }
    if (tenureMonths <= 0) {
      throw ArgumentError(
        'Tenure must be a positive integer. Got: $tenureMonths',
      );
    }
    if (emi <= 0) {
      throw ArgumentError('EMI must be a positive number. Got: $emi');
    }

    // Check if EMI is at least enough to cover first month's interest
    final firstMonthInterest = principal * (annualInterestRate / 12 / 100);
    // Use slight tolerance for float comparison
    if (emi < firstMonthInterest - 0.1) {
      throw ArgumentError(
        'EMI ($emi) must be greater than the first month\'s interest '
        '($firstMonthInterest) to ensure principal reduction.',
      );
    }
  }

  /// Adds a specified number of months to a date.
  DateTime _addMonths(DateTime date, int months) {
    int targetYear = date.year;
    int targetMonth = date.month + months;

    while (targetMonth > 12) {
      targetYear++;
      targetMonth -= 12;
    }

    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;

    return DateTime(targetYear, targetMonth, targetDay);
  }

  /// Helper for display formatting only (not used in core logic)
  static double _roundToDecimalPlaces(double value, int places) {
    final multiplier = pow(10, places);
    return (value * multiplier).round() / multiplier;
  }
}
