import 'dart:math';

import '../entities/loan/loan_barrel.dart';

/// A pure, deterministic reducing-balance loan amortization engine.
///
/// This engine calculates the complete amortization schedule for a loan
/// using the reducing balance method, where interest is computed on the
/// outstanding principal balance each month.
///
/// ## Usage Example:
/// ```dart
/// final engine = LoanAmortizationEngine();
/// final summary = engine.generateAmortizationSchedule(
///   principal: 100000,
///   annualInterestRate: 12.0,
///   tenureMonths: 12,
///   emi: 8884.88,
///   startDate: DateTime(2024, 1, 1),
/// );
/// ```
///
/// === ENGINEERING NOTES ===
///
/// ## EMI Formula Used
///
/// The standard EMI formula for reducing balance loans is:
///
/// ```
/// EMI = P × r × (1 + r)^n / [(1 + r)^n - 1]
/// ```
///
/// Where:
/// - P = Principal loan amount
/// - r = Monthly interest rate (Annual Rate / 12 / 100)
/// - n = Tenure in months
///
/// However, this engine ACCEPTS the EMI as an input rather than calculating it.
/// This design choice allows:
/// 1. Flexibility to handle custom EMI amounts
/// 2. Support for pre-negotiated EMI values from lenders
/// 3. Easier testing with known EMI values
///
/// The engine provides a static helper method `calculateEmi()` if EMI
/// calculation is needed.
///
/// ## How Rounding is Handled
///
/// 1. **Interest Calculation**: Interest for each month is calculated as:
///    `remainingBalance × monthlyInterestRate`
///    This is rounded to 2 decimal places using `roundToDecimalPlaces()`.
///
/// 2. **Principal Portion**: Calculated as `EMI - Interest` for each month.
///
/// 3. **Final Payment Adjustment**: The last EMI may be adjusted to exactly
///    close out the remaining balance, preventing small residual amounts
///    due to cumulative rounding errors.
///
/// 4. **Precision**: All monetary values are rounded to 2 decimal places
///    to represent currency accurately.
///
/// ## Edge Cases Considered
///
/// 1. **Zero Interest Rate**: If annual interest rate is 0, the entire EMI
///    goes towards principal repayment.
///
/// 2. **EMI Less Than Interest**: If the EMI is insufficient to cover even
///    the interest for a month, the loan balance would grow (negative
///    amortization). This is detected and throws an `ArgumentError`.
///
/// 3. **Rounding Residuals**: The final payment is adjusted to exactly
///    match the remaining balance, preventing small positive/negative
///    residuals.
///
/// 4. **Early Closure**: If the EMI is higher than the mathematically
///    computed EMI, the loan will close early. The engine detects this
///    and generates a shorter schedule.
///
/// 5. **Month-End Date Handling**: Payment dates are calculated by adding
///    months to the start date. Dart's DateTime handles month-end edge
///    cases (e.g., Jan 31 + 1 month = Feb 28/29).
///
/// ## Limitations of MVP Logic
///
/// 1. **No Prepayment Support**: This MVP assumes all EMIs are paid on time
///    with no prepayments. Part-payments or lump-sum prepayments are not
///    supported.
///
/// 2. **No Late Payment/Penalty**: No modeling of late payment fees,
///    penalty interest, or grace periods.
///
/// 3. **No Variable Interest Rates**: The interest rate is fixed for the
///    entire tenure. Floating rate scenarios are not supported.
///
/// 4. **No Processing Fees/Charges**: The engine does not account for
///    loan processing fees, insurance, or other charges.
///
/// 5. **Assumes Monthly Payments**: Only monthly payment frequency is
///    supported. Weekly, bi-weekly, or quarterly payments are not.
///
/// 6. **No Holiday/Weekend Adjustment**: Payment dates are not adjusted
///    for holidays or weekends.
///
/// 7. **Double Precision Limitations**: Uses Dart's `double` type which
///    has floating-point precision limitations. For financial applications
///    requiring absolute precision, consider using a Decimal library.
///
/// 8. **No Currency Handling**: Values are treated as raw numbers without
///    currency context or localization.
///
class LoanAmortizationEngine {
  const LoanAmortizationEngine();

  /// Number of decimal places for monetary rounding
  static const int _decimalPlaces = 2;

  /// Tolerance for considering a balance as zero (to handle floating-point errors)
  static const double _zeroTolerance = 0.01;

  /// Generates a complete amortization schedule for the given loan parameters.
  ///
  /// Parameters:
  /// - [principal]: The original loan amount
  /// - [annualInterestRate]: Annual interest rate as a percentage (e.g., 12.5 for 12.5%)
  /// - [tenureMonths]: Total loan tenure in months
  /// - [emi]: Monthly EMI amount
  /// - [startDate]: Date of the first EMI payment
  ///
  /// Returns a [LoanSummary] containing the complete amortization schedule
  /// and aggregated loan metrics.
  ///
  /// Throws [ArgumentError] if any input parameters are invalid.
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
    int monthNumber = 0;

    // Generate schedule until balance is paid off or tenure is reached
    while (remainingBalance > _zeroTolerance && monthNumber < tenureMonths) {
      monthNumber++;

      // Calculate payment date for this month
      final paymentDate = _addMonths(startDate, monthNumber - 1);

      // Calculate interest for this month on remaining balance
      double interestForMonth = _roundToDecimalPlaces(
        remainingBalance * monthlyInterestRate,
        _decimalPlaces,
      );

      // Calculate principal portion
      double principalForMonth;
      double actualEmi;

      // Check if this is the last payment or if remaining balance is less than full EMI principal
      final principalIfFullEmi = emi - interestForMonth;

      if (remainingBalance <= principalIfFullEmi + _zeroTolerance) {
        // Final payment - adjust to exact remaining balance
        principalForMonth = _roundToDecimalPlaces(
          remainingBalance,
          _decimalPlaces,
        );
        actualEmi = _roundToDecimalPlaces(
          principalForMonth + interestForMonth,
          _decimalPlaces,
        );
      } else {
        // Normal payment
        principalForMonth = _roundToDecimalPlaces(
          principalIfFullEmi,
          _decimalPlaces,
        );
        actualEmi = emi;
      }

      // Validate that EMI covers at least the interest
      if (principalForMonth < 0) {
        throw ArgumentError(
          'EMI of $emi is insufficient to cover interest of $interestForMonth. '
          'The loan would experience negative amortization.',
        );
      }

      // Update running totals
      remainingBalance = _roundToDecimalPlaces(
        remainingBalance - principalForMonth,
        _decimalPlaces,
      );

      // Handle floating-point edge case where balance might be slightly negative
      if (remainingBalance < 0) {
        remainingBalance = 0;
      }

      cumulativePrincipalPaid = _roundToDecimalPlaces(
        cumulativePrincipalPaid + principalForMonth,
        _decimalPlaces,
      );
      cumulativeInterestPaid = _roundToDecimalPlaces(
        cumulativeInterestPaid + interestForMonth,
        _decimalPlaces,
      );

      // Create schedule entry
      schedule.add(
        AmortizationEntry(
          monthNumber: monthNumber,
          paymentDate: paymentDate,
          emiPaid: actualEmi,
          principalPortion: principalForMonth,
          interestPortion: interestForMonth,
          remainingBalance: remainingBalance,
          cumulativePrincipalPaid: cumulativePrincipalPaid,
          cumulativeInterestPaid: cumulativeInterestPaid,
        ),
      );
    }

    // Calculate final totals
    final totalAmountPayable = _roundToDecimalPlaces(
      cumulativePrincipalPaid + cumulativeInterestPaid,
      _decimalPlaces,
    );
    final totalInterestPayable = cumulativeInterestPaid;

    // Calculate expected closure date (last payment date)
    final expectedClosureDate = schedule.isNotEmpty
        ? schedule.last.paymentDate
        : startDate;

    return LoanSummary(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      emi: emi,
      startDate: startDate,
      schedule: schedule,
      totalAmountPayable: totalAmountPayable,
      totalInterestPayable: totalInterestPayable,
      expectedClosureDate: expectedClosureDate,
    );
  }

  /// Calculates the standard EMI for given loan parameters.
  ///
  /// Uses the standard reducing balance EMI formula:
  /// EMI = P × r × (1 + r)^n / [(1 + r)^n - 1]
  ///
  /// Parameters:
  /// - [principal]: The loan amount
  /// - [annualInterestRate]: Annual interest rate as percentage
  /// - [tenureMonths]: Loan tenure in months
  ///
  /// Returns the calculated EMI rounded to 2 decimal places.
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
      return _roundToDecimalPlaces(principal / tenureMonths, _decimalPlaces);
    }

    final r = annualInterestRate / 12 / 100; // Monthly interest rate
    final n = tenureMonths;

    // EMI = P × r × (1 + r)^n / [(1 + r)^n - 1]
    final onePlusRPowerN = pow(1 + r, n);
    final emi = principal * r * onePlusRPowerN / (onePlusRPowerN - 1);

    return _roundToDecimalPlaces(emi, _decimalPlaces);
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
    if (emi <= firstMonthInterest) {
      throw ArgumentError(
        'EMI ($emi) must be greater than the first month\'s interest '
        '($firstMonthInterest) to ensure principal reduction.',
      );
    }
  }

  /// Adds a specified number of months to a date.
  ///
  /// Handles edge cases like month-end dates appropriately.
  /// For example: Jan 31 + 1 month = Feb 28/29
  DateTime _addMonths(DateTime date, int months) {
    // Calculate target year and month
    int targetYear = date.year;
    int targetMonth = date.month + months;

    // Normalize month (handle overflow)
    while (targetMonth > 12) {
      targetYear++;
      targetMonth -= 12;
    }

    // Get the last day of the target month
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    // Use the same day if possible, otherwise use the last day of the month
    final targetDay = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;

    return DateTime(targetYear, targetMonth, targetDay);
  }

  /// Rounds a double to the specified number of decimal places.
  static double _roundToDecimalPlaces(double value, int places) {
    final multiplier = pow(10, places);
    return (value * multiplier).round() / multiplier;
  }
}
