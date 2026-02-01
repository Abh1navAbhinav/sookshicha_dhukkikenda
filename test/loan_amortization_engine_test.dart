import 'package:flutter_test/flutter_test.dart';
import 'package:sookshicha_dhukkikenda/domain/domain.dart';

void main() {
  group('LoanAmortizationEngine', () {
    late LoanAmortizationEngine engine;

    setUp(() {
      engine = const LoanAmortizationEngine();
    });

    group('EMI Calculation', () {
      test('should calculate correct EMI for standard loan', () {
        // Principal: 100,000, Rate: 12%, Tenure: 12 months
        // Expected EMI ≈ 8,884.88
        final emi = LoanAmortizationEngine.calculateEmi(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
        );

        expect(emi, closeTo(8884.88, 0.01));
      });

      test('should calculate correct EMI for zero interest rate', () {
        final emi = LoanAmortizationEngine.calculateEmi(
          principal: 120000,
          annualInterestRate: 0,
          tenureMonths: 12,
        );

        expect(emi, equals(10000.0));
      });

      test('should calculate correct EMI for high interest rate', () {
        // Principal: 500,000, Rate: 18%, Tenure: 36 months
        final emi = LoanAmortizationEngine.calculateEmi(
          principal: 500000,
          annualInterestRate: 18.0,
          tenureMonths: 36,
        );

        expect(emi, closeTo(18076.32, 0.15));
      });

      test('should throw ArgumentError for zero principal', () {
        expect(
          () => LoanAmortizationEngine.calculateEmi(
            principal: 0,
            annualInterestRate: 12.0,
            tenureMonths: 12,
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for zero tenure', () {
        expect(
          () => LoanAmortizationEngine.calculateEmi(
            principal: 100000,
            annualInterestRate: 12.0,
            tenureMonths: 0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Amortization Schedule Generation', () {
      test('should generate correct schedule for 12-month loan', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        // Verify schedule length
        expect(summary.schedule.length, equals(12));

        // Verify first entry
        final firstEntry = summary.schedule.first;
        expect(firstEntry.monthNumber, equals(1));
        expect(firstEntry.paymentDate, equals(DateTime(2024, 1, 1)));
        expect(firstEntry.interestPortion, equals(1000.0)); // 100000 * 0.01
        expect(firstEntry.principalPortion, closeTo(7884.88, 0.01));
        expect(firstEntry.remainingBalance, closeTo(92115.12, 0.01));

        // Verify last entry has zero (or near-zero) remaining balance
        final lastEntry = summary.schedule.last;
        expect(lastEntry.monthNumber, equals(12));
        expect(lastEntry.remainingBalance, closeTo(0, 0.5));
      });

      test('should calculate correct totals', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        // Total amount payable should be approximately 12 * EMI = 106,618.56
        // But last payment may be adjusted
        expect(summary.totalAmountPayable, closeTo(106618.56, 10));

        // Total interest should be approximately 6,618.56
        expect(summary.totalInterestPayable, closeTo(6618.56, 10));

        // Principal repaid should equal original principal
        final totalPrincipalRepaid = summary.schedule
            .map((e) => e.principalPortion)
            .reduce((a, b) => a + b);
        expect(totalPrincipalRepaid, closeTo(100000, 1));
      });

      test('should handle zero interest rate correctly', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 12000,
          annualInterestRate: 0,
          tenureMonths: 12,
          emi: 1000,
          startDate: DateTime(2024, 1, 1),
        );

        // All interest portions should be zero
        for (final entry in summary.schedule) {
          expect(entry.interestPortion, equals(0.0));
          expect(entry.principalPortion, equals(1000.0));
        }

        expect(summary.totalInterestPayable, equals(0.0));
        expect(summary.totalAmountPayable, equals(12000.0));
      });

      test('should handle early closure when EMI is higher than needed', () {
        // Higher EMI should result in fewer payments
        final summary = engine.generateAmortizationSchedule(
          principal: 10000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 5000, // Much higher than calculated EMI (~888)
          startDate: DateTime(2024, 1, 1),
        );

        // Should close in fewer than 12 months
        expect(summary.schedule.length, lessThan(12));
        expect(summary.schedule.last.remainingBalance, closeTo(0, 0.1));
      });

      test('should calculate correct payment dates', () {
        final startDate = DateTime(2024, 1, 15);
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 6,
          emi: 17255.61, // Calculated EMI for 6 months
          startDate: startDate,
        );

        expect(summary.schedule[0].paymentDate, equals(DateTime(2024, 1, 15)));
        expect(summary.schedule[1].paymentDate, equals(DateTime(2024, 2, 15)));
        expect(summary.schedule[2].paymentDate, equals(DateTime(2024, 3, 15)));
        expect(summary.schedule[3].paymentDate, equals(DateTime(2024, 4, 15)));
        expect(summary.schedule[4].paymentDate, equals(DateTime(2024, 5, 15)));
        expect(summary.schedule[5].paymentDate, equals(DateTime(2024, 6, 15)));
      });

      test('should handle month-end dates correctly', () {
        // Start on Jan 31
        final startDate = DateTime(2024, 1, 31);
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 3,
          emi: 34002.21, // Calculated EMI for 3 months
          startDate: startDate,
        );

        expect(summary.schedule[0].paymentDate, equals(DateTime(2024, 1, 31)));
        // February doesn't have 31 days, should be Feb 29 (2024 is leap year)
        expect(summary.schedule[1].paymentDate, equals(DateTime(2024, 2, 29)));
        expect(summary.schedule[2].paymentDate, equals(DateTime(2024, 3, 31)));
      });

      test('should set expected closure date correctly', () {
        final startDate = DateTime(2024, 1, 1);
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: startDate,
        );

        // Expected closure date should be the last payment date
        expect(summary.expectedClosureDate, equals(DateTime(2024, 12, 1)));
      });
    });

    group('Cumulative Calculations', () {
      test('should track cumulative amounts correctly', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        // Verify cumulative principal increases monotonically
        double previousCumulativePrincipal = 0;
        for (final entry in summary.schedule) {
          expect(
            entry.cumulativePrincipalPaid,
            greaterThan(previousCumulativePrincipal),
          );
          previousCumulativePrincipal = entry.cumulativePrincipalPaid;
        }

        // Verify cumulative interest increases monotonically
        double previousCumulativeInterest = 0;
        for (final entry in summary.schedule) {
          expect(
            entry.cumulativeInterestPaid,
            greaterThan(previousCumulativeInterest),
          );
          previousCumulativeInterest = entry.cumulativeInterestPaid;
        }

        // Verify final cumulative values match totals
        final lastEntry = summary.schedule.last;
        expect(
          lastEntry.cumulativePrincipalPaid + lastEntry.cumulativeInterestPaid,
          closeTo(summary.totalAmountPayable, 0.01),
        );
      });
    });

    group('Input Validation', () {
      test('should throw ArgumentError for negative principal', () {
        expect(
          () => engine.generateAmortizationSchedule(
            principal: -100000,
            annualInterestRate: 12.0,
            tenureMonths: 12,
            emi: 8884.88,
            startDate: DateTime(2024, 1, 1),
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for negative interest rate', () {
        expect(
          () => engine.generateAmortizationSchedule(
            principal: 100000,
            annualInterestRate: -5.0,
            tenureMonths: 12,
            emi: 8884.88,
            startDate: DateTime(2024, 1, 1),
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for zero tenure', () {
        expect(
          () => engine.generateAmortizationSchedule(
            principal: 100000,
            annualInterestRate: 12.0,
            tenureMonths: 0,
            emi: 8884.88,
            startDate: DateTime(2024, 1, 1),
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for negative EMI', () {
        expect(
          () => engine.generateAmortizationSchedule(
            principal: 100000,
            annualInterestRate: 12.0,
            tenureMonths: 12,
            emi: -8884.88,
            startDate: DateTime(2024, 1, 1),
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError when EMI is less than interest', () {
        // First month interest on 100000 at 12% annual = 1000
        // EMI of 500 is less than interest, so loan would never reduce
        expect(
          () => engine.generateAmortizationSchedule(
            principal: 100000,
            annualInterestRate: 12.0,
            tenureMonths: 12,
            emi: 500,
            startDate: DateTime(2024, 1, 1),
          ),
          throwsArgumentError,
        );
      });
    });

    group('LoanSummary.getStatusAtDate', () {
      test('should return initial status before start date', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        final status = summary.getStatusAtDate(DateTime(2023, 12, 15));

        expect(status.monthsCompleted, equals(0));
        expect(status.totalAmountPaid, equals(0));
        expect(status.remainingPrincipal, equals(100000));
        expect(status.remainingMonths, equals(12));
        expect(status.isLoanClosed, isFalse);
      });

      test('should return correct status after partial payments', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        // Query status after 3 months
        final status = summary.getStatusAtDate(DateTime(2024, 3, 15));

        expect(status.monthsCompleted, equals(3));
        expect(status.remainingMonths, equals(9));
        expect(status.totalAmountPaid, greaterThan(0));
        expect(status.remainingPrincipal, lessThan(100000));
        expect(status.isLoanClosed, isFalse);
      });

      test('should return closed status after all payments', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        // Query status after loan is complete
        final status = summary.getStatusAtDate(DateTime(2025, 1, 1));

        expect(status.monthsCompleted, equals(12));
        expect(status.isLoanClosed, isTrue);
        expect(status.remainingPrincipal, closeTo(0, 0.5));
      });
    });

    group('Serialization', () {
      test('should serialize and deserialize AmortizationEntry correctly', () {
        final entry = AmortizationEntry(
          monthNumber: 1,
          paymentDate: DateTime(2024, 1, 1),
          emiPaid: 8884.88,
          principalPortion: 7884.88,
          interestPortion: 1000.0,
          remainingBalance: 92115.12,
          cumulativePrincipalPaid: 7884.88,
          cumulativeInterestPaid: 1000.0,
        );

        final json = entry.toJson();
        final deserializedEntry = AmortizationEntry.fromJson(json);

        expect(deserializedEntry, equals(entry));
      });

      test('should serialize and deserialize LoanSummary correctly', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 50000,
          annualInterestRate: 10.0,
          tenureMonths: 6,
          emi: 8573.47,
          startDate: DateTime(2024, 1, 1),
        );

        final json = summary.toJson();
        final deserializedSummary = LoanSummary.fromJson(json);

        expect(deserializedSummary.principal, equals(summary.principal));
        expect(
          deserializedSummary.annualInterestRate,
          equals(summary.annualInterestRate),
        );
        expect(deserializedSummary.tenureMonths, equals(summary.tenureMonths));
        expect(
          deserializedSummary.schedule.length,
          equals(summary.schedule.length),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very small loan amounts', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100,
          annualInterestRate: 12.0,
          tenureMonths: 3,
          emi: 34.00,
          startDate: DateTime(2024, 1, 1),
        );

        expect(summary.schedule.isNotEmpty, isTrue);
        expect(summary.schedule.last.remainingBalance, closeTo(0, 1));
      });

      test('should handle very high interest rate', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 10000,
          annualInterestRate: 36.0, // 36% annual = 3% monthly
          tenureMonths: 12,
          emi: 1004.62, // Calculated EMI
          startDate: DateTime(2024, 1, 1),
        );

        expect(summary.schedule.length, equals(12));
        // Higher interest rate means more total interest paid
        expect(summary.totalInterestPayable, greaterThan(2000));
      });

      test('should handle single month tenure', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 10000,
          annualInterestRate: 12.0,
          tenureMonths: 1,
          emi: 10100, // Principal + 1 month interest
          startDate: DateTime(2024, 1, 1),
        );

        expect(summary.schedule.length, equals(1));
        expect(summary.schedule.first.principalPortion, equals(10000));
        expect(summary.schedule.first.interestPortion, equals(100));
        expect(summary.schedule.first.remainingBalance, equals(0));
      });

      test('should be deterministic - same inputs produce same outputs', () {
        final summary1 = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        final summary2 = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        expect(summary1.schedule.length, equals(summary2.schedule.length));
        expect(
          summary1.totalAmountPayable,
          equals(summary2.totalAmountPayable),
        );
        expect(
          summary1.totalInterestPayable,
          equals(summary2.totalInterestPayable),
        );

        for (int i = 0; i < summary1.schedule.length; i++) {
          expect(summary1.schedule[i], equals(summary2.schedule[i]));
        }
      });
    });

    group('Real-world Scenarios', () {
      test('should correctly calculate home loan scenario', () {
        // 50 Lakh home loan at 8.5% for 20 years
        const principal = 5000000.0;
        const annualRate = 8.5;
        const tenureMonths = 240;
        final emi = LoanAmortizationEngine.calculateEmi(
          principal: principal,
          annualInterestRate: annualRate,
          tenureMonths: tenureMonths,
        );

        final summary = engine.generateAmortizationSchedule(
          principal: principal,
          annualInterestRate: annualRate,
          tenureMonths: tenureMonths,
          emi: emi,
          startDate: DateTime(2024, 1, 1),
        );

        // EMI should be around 43,391
        expect(emi, closeTo(43391, 1));

        // Total payment should be around 1,04,14,000
        expect(summary.totalAmountPayable, closeTo(10413840, 1000));

        // Verify schedule length
        expect(summary.schedule.length, equals(240));
      });

      test('should correctly calculate car loan scenario', () {
        // 8 Lakh car loan at 9% for 5 years
        const principal = 800000.0;
        const annualRate = 9.0;
        const tenureMonths = 60;
        final emi = LoanAmortizationEngine.calculateEmi(
          principal: principal,
          annualInterestRate: annualRate,
          tenureMonths: tenureMonths,
        );

        final summary = engine.generateAmortizationSchedule(
          principal: principal,
          annualInterestRate: annualRate,
          tenureMonths: tenureMonths,
          emi: emi,
          startDate: DateTime(2024, 1, 1),
        );

        // EMI should be around 16,607
        expect(emi, closeTo(16607, 1));

        // Total interest paid
        expect(summary.totalInterestPayable, closeTo(196420, 100));
      });
    });
    group('Invariants', () {
      test('should satisfy UI model invariants for every month', () {
        final summary = engine.generateAmortizationSchedule(
          principal: 100000,
          annualInterestRate: 12.0,
          tenureMonths: 12,
          emi: 8884.88,
          startDate: DateTime(2024, 1, 1),
        );

        final totalPayable = summary.totalAmountPayable;
        final totalInterest = summary.totalInterestPayable;

        for (final entry in summary.schedule) {
          final principalPaidTillDate = entry.cumulativePrincipalPaid;
          final interestPaidTillDate = entry.cumulativeInterestPaid;
          final totalPaid = principalPaidTillDate + interestPaidTillDate;

          final remainingPrincipal = entry.remainingBalance;
          final remainingInterest = totalInterest - interestPaidTillDate;
          final derivedRemainingBalance =
              remainingPrincipal + remainingInterest;

          // Invariant 1: Remaining Balance = Total Payable - Total Paid
          final calculatedRemainingBalance = totalPayable - totalPaid;

          expect(
            derivedRemainingBalance,
            closeTo(calculatedRemainingBalance, 0.1),
            reason:
                'Month ${entry.monthNumber}: Derived Balance != Calculated Balance',
          );

          // Invariant 2: Principal Paid + Remaining Principal = Total Principal (approx)
          expect(
            principalPaidTillDate + remainingPrincipal,
            closeTo(summary.principal, 1.0), // Allow slight rounding drift
            reason: 'Month ${entry.monthNumber}: Principal check failed',
          );
        }
      });
    });
  });
}
