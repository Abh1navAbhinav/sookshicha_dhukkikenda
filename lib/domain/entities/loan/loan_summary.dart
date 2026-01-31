import 'package:equatable/equatable.dart';

import 'amortization_entry.dart';

/// Represents a complete loan summary with amortization schedule.
///
/// Contains all the computed loan details including the full payment
/// schedule and aggregated summary metrics.
class LoanSummary extends Equatable {
  const LoanSummary({
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    required this.emi,
    required this.startDate,
    required this.schedule,
    required this.totalAmountPayable,
    required this.totalInterestPayable,
    required this.expectedClosureDate,
  });

  /// The original loan principal amount
  final double principal;

  /// Annual interest rate in percentage (e.g., 12.5 for 12.5%)
  final double annualInterestRate;

  /// Total loan tenure in months
  final int tenureMonths;

  /// Monthly EMI amount
  final double emi;

  /// The date when the loan starts / first EMI is due
  final DateTime startDate;

  /// Complete amortization schedule with all monthly entries
  final List<AmortizationEntry> schedule;

  /// Total amount payable over the entire loan tenure
  final double totalAmountPayable;

  /// Total interest payable over the entire loan tenure
  final double totalInterestPayable;

  /// Expected date when the loan will be fully paid off
  final DateTime expectedClosureDate;

  /// Monthly interest rate (annual rate / 12 / 100)
  double get monthlyInterestRate => annualInterestRate / 12 / 100;

  /// Gets the current status at a specific month number (1-indexed)
  /// Returns null if month number is out of range
  AmortizationEntry? getEntryAtMonth(int monthNumber) {
    if (monthNumber < 1 || monthNumber > schedule.length) {
      return null;
    }
    return schedule[monthNumber - 1];
  }

  /// Gets loan status at a specific date
  /// Returns the most recent entry on or before the given date
  LoanStatusAtDate getStatusAtDate(DateTime date) {
    if (date.isBefore(startDate)) {
      return LoanStatusAtDate(
        asOfDate: date,
        monthsCompleted: 0,
        totalAmountPaid: 0,
        totalInterestPaid: 0,
        remainingPrincipal: principal,
        remainingMonths: tenureMonths,
        expectedClosureDate: expectedClosureDate,
        isLoanClosed: false,
      );
    }

    AmortizationEntry? lastEntry;
    for (final entry in schedule) {
      if (entry.paymentDate.isAfter(date)) {
        break;
      }
      lastEntry = entry;
    }

    if (lastEntry == null) {
      return LoanStatusAtDate(
        asOfDate: date,
        monthsCompleted: 0,
        totalAmountPaid: 0,
        totalInterestPaid: 0,
        remainingPrincipal: principal,
        remainingMonths: tenureMonths,
        expectedClosureDate: expectedClosureDate,
        isLoanClosed: false,
      );
    }

    final isLoanClosed = lastEntry.remainingBalance <= 0.01;

    return LoanStatusAtDate(
      asOfDate: date,
      monthsCompleted: lastEntry.monthNumber,
      totalAmountPaid: lastEntry.cumulativeTotalPaid,
      totalInterestPaid: lastEntry.cumulativeInterestPaid,
      remainingPrincipal: lastEntry.remainingBalance,
      remainingMonths: tenureMonths - lastEntry.monthNumber,
      expectedClosureDate: expectedClosureDate,
      isLoanClosed: isLoanClosed,
    );
  }

  @override
  List<Object?> get props => [
    principal,
    annualInterestRate,
    tenureMonths,
    emi,
    startDate,
    schedule,
    totalAmountPayable,
    totalInterestPayable,
    expectedClosureDate,
  ];

  /// Converts the loan summary to a JSON-compatible map
  Map<String, dynamic> toJson() {
    return {
      'principal': principal,
      'annualInterestRate': annualInterestRate,
      'tenureMonths': tenureMonths,
      'emi': emi,
      'startDate': startDate.toIso8601String(),
      'schedule': schedule.map((e) => e.toJson()).toList(),
      'totalAmountPayable': totalAmountPayable,
      'totalInterestPayable': totalInterestPayable,
      'expectedClosureDate': expectedClosureDate.toIso8601String(),
    };
  }

  /// Creates a loan summary from a JSON-compatible map
  factory LoanSummary.fromJson(Map<String, dynamic> json) {
    return LoanSummary(
      principal: (json['principal'] as num).toDouble(),
      annualInterestRate: (json['annualInterestRate'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      emi: (json['emi'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      schedule: (json['schedule'] as List)
          .map((e) => AmortizationEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmountPayable: (json['totalAmountPayable'] as num).toDouble(),
      totalInterestPayable: (json['totalInterestPayable'] as num).toDouble(),
      expectedClosureDate: DateTime.parse(
        json['expectedClosureDate'] as String,
      ),
    );
  }
}

/// Represents the loan status at a specific point in time.
///
/// Useful for querying how much has been paid, how much remains, etc.
/// at any given date during the loan tenure.
class LoanStatusAtDate extends Equatable {
  const LoanStatusAtDate({
    required this.asOfDate,
    required this.monthsCompleted,
    required this.totalAmountPaid,
    required this.totalInterestPaid,
    required this.remainingPrincipal,
    required this.remainingMonths,
    required this.expectedClosureDate,
    required this.isLoanClosed,
  });

  /// The date for which this status is calculated
  final DateTime asOfDate;

  /// Number of EMI payments completed
  final int monthsCompleted;

  /// Total amount paid so far (principal + interest)
  final double totalAmountPaid;

  /// Total interest paid so far
  final double totalInterestPaid;

  /// Remaining principal balance
  final double remainingPrincipal;

  /// Remaining months until loan closure
  final int remainingMonths;

  /// Expected loan closure date
  final DateTime expectedClosureDate;

  /// Whether the loan has been fully paid off
  final bool isLoanClosed;

  /// Total principal paid so far
  double get totalPrincipalPaid => totalAmountPaid - totalInterestPaid;

  @override
  List<Object?> get props => [
    asOfDate,
    monthsCompleted,
    totalAmountPaid,
    totalInterestPaid,
    remainingPrincipal,
    remainingMonths,
    expectedClosureDate,
    isLoanClosed,
  ];

  /// Converts to a JSON-compatible map
  Map<String, dynamic> toJson() {
    return {
      'asOfDate': asOfDate.toIso8601String(),
      'monthsCompleted': monthsCompleted,
      'totalAmountPaid': totalAmountPaid,
      'totalInterestPaid': totalInterestPaid,
      'remainingPrincipal': remainingPrincipal,
      'remainingMonths': remainingMonths,
      'expectedClosureDate': expectedClosureDate.toIso8601String(),
      'isLoanClosed': isLoanClosed,
    };
  }
}
