import 'package:equatable/equatable.dart';

/// Represents a single entry in the loan amortization schedule.
///
/// Each entry corresponds to one EMI payment and contains the breakdown
/// of principal and interest components along with the remaining balance.
class AmortizationEntry extends Equatable {
  const AmortizationEntry({
    required this.monthNumber,
    required this.paymentDate,
    required this.emiPaid,
    required this.principalPortion,
    required this.interestPortion,
    required this.remainingBalance,
    required this.cumulativePrincipalPaid,
    required this.cumulativeInterestPaid,
  });

  /// The month number of this payment (1-indexed)
  final int monthNumber;

  /// The date when this EMI payment is due
  final DateTime paymentDate;

  /// The EMI amount paid for this month
  final double emiPaid;

  /// The portion of EMI that goes towards principal repayment
  final double principalPortion;

  /// The portion of EMI that goes towards interest payment
  final double interestPortion;

  /// The outstanding principal balance after this payment
  final double remainingBalance;

  /// Total principal paid up to and including this payment
  final double cumulativePrincipalPaid;

  /// Total interest paid up to and including this payment
  final double cumulativeInterestPaid;

  /// Total amount paid up to and including this payment
  double get cumulativeTotalPaid =>
      cumulativePrincipalPaid + cumulativeInterestPaid;

  @override
  List<Object?> get props => [
    monthNumber,
    paymentDate,
    emiPaid,
    principalPortion,
    interestPortion,
    remainingBalance,
    cumulativePrincipalPaid,
    cumulativeInterestPaid,
  ];

  /// Creates a copy of this entry with optional field overrides
  AmortizationEntry copyWith({
    int? monthNumber,
    DateTime? paymentDate,
    double? emiPaid,
    double? principalPortion,
    double? interestPortion,
    double? remainingBalance,
    double? cumulativePrincipalPaid,
    double? cumulativeInterestPaid,
  }) {
    return AmortizationEntry(
      monthNumber: monthNumber ?? this.monthNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      emiPaid: emiPaid ?? this.emiPaid,
      principalPortion: principalPortion ?? this.principalPortion,
      interestPortion: interestPortion ?? this.interestPortion,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      cumulativePrincipalPaid:
          cumulativePrincipalPaid ?? this.cumulativePrincipalPaid,
      cumulativeInterestPaid:
          cumulativeInterestPaid ?? this.cumulativeInterestPaid,
    );
  }

  /// Converts this entry to a JSON-compatible map
  Map<String, dynamic> toJson() {
    return {
      'monthNumber': monthNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'emiPaid': emiPaid,
      'principalPortion': principalPortion,
      'interestPortion': interestPortion,
      'remainingBalance': remainingBalance,
      'cumulativePrincipalPaid': cumulativePrincipalPaid,
      'cumulativeInterestPaid': cumulativeInterestPaid,
    };
  }

  /// Creates an entry from a JSON-compatible map
  factory AmortizationEntry.fromJson(Map<String, dynamic> json) {
    return AmortizationEntry(
      monthNumber: json['monthNumber'] as int,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      emiPaid: (json['emiPaid'] as num).toDouble(),
      principalPortion: (json['principalPortion'] as num).toDouble(),
      interestPortion: (json['interestPortion'] as num).toDouble(),
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      cumulativePrincipalPaid: (json['cumulativePrincipalPaid'] as num)
          .toDouble(),
      cumulativeInterestPaid: (json['cumulativeInterestPaid'] as num)
          .toDouble(),
    );
  }

  @override
  String toString() {
    return 'AmortizationEntry(month: $monthNumber, EMI: $emiPaid, '
        'principal: $principalPortion, interest: $interestPortion, '
        'balance: $remainingBalance)';
  }
}
