import 'package:flutter_test/flutter_test.dart';
import 'package:sookshicha_dhukkikenda/domain/domain.dart';

void main() {
  group('MonthlyExecutionEngine', () {
    late MonthlyExecutionEngine engine;

    setUp(() {
      engine = const MonthlyExecutionEngine();
    });

    group('executeMonth', () {
      test('should return empty snapshot when no contracts provided', () {
        final snapshot = engine.executeMonth(
          contracts: [],
          month: 1,
          year: 2026,
          totalIncome: 100000,
        );

        expect(snapshot.month, 1);
        expect(snapshot.year, 2026);
        expect(snapshot.totalIncome, 100000);
        expect(snapshot.mandatoryOutflow, 0);
        expect(snapshot.freeBalance, 100000);
        expect(snapshot.activeContractCount, 0);
      });

      test('should filter only active contracts', () {
        final contracts = [
          _createReducingContract(id: 'active', status: ContractStatus.active),
          _createReducingContract(id: 'paused', status: ContractStatus.paused),
          _createReducingContract(id: 'closed', status: ContractStatus.closed),
        ];

        final snapshot = engine.executeMonth(
          contracts: contracts,
          month: 6,
          year: 2026,
          totalIncome: 100000,
        );

        expect(snapshot.activeContractCount, 1);
      });

      test('should exclude contracts not yet started', () {
        final contract = _createReducingContract(
          id: 'future',
          status: ContractStatus.active,
          startDate: DateTime(2026, 12, 1), // Starts in Dec
        );

        final snapshot = engine.executeMonth(
          contracts: [contract],
          month: 6, // June - before contract starts
          year: 2026,
        );

        expect(snapshot.activeContractCount, 0);
      });

      test('should exclude contracts that have ended', () {
        final contract = _createReducingContract(
          id: 'past',
          status: ContractStatus.active,
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31), // Ended Dec 2025
        );

        final snapshot = engine.executeMonth(
          contracts: [contract],
          month: 6, // June 2026 - after contract ended
          year: 2026,
        );

        expect(snapshot.activeContractCount, 0);
      });

      test('should calculate reducing contract contribution correctly', () {
        final contract = _createReducingContract(
          id: 'loan',
          status: ContractStatus.active,
          emiAmount: 10000,
          remainingBalance: 100000,
          interestRate: 12, // 1% monthly
        );

        final snapshot = engine.executeMonth(
          contracts: [contract],
          month: 6,
          year: 2026,
        );

        expect(snapshot.reducingOutflow, 10000);
        expect(snapshot.mandatoryOutflow, 10000);

        // Check breakdown
        final contribution = snapshot.contractBreakdown!.first;
        expect(contribution.amount, 10000);
        expect(contribution.interestPortion, 1000); // 1% of 100000
        expect(contribution.principalPortion, 9000); // 10000 - 1000
        expect(contribution.newBalance, 91000); // 100000 - 9000
      });

      test('should calculate growing contract contribution correctly', () {
        final contract = _createGrowingContract(
          id: 'sip',
          status: ContractStatus.active,
          monthlyAmount: 5000,
          totalInvested: 60000,
        );

        final snapshot = engine.executeMonth(
          contracts: [contract],
          month: 6,
          year: 2026,
        );

        expect(snapshot.growingOutflow, 5000);
        expect(snapshot.mandatoryOutflow, 5000);

        final contribution = snapshot.contractBreakdown!.first;
        expect(contribution.amount, 5000);
        expect(contribution.newInvestedTotal, 65000); // 60000 + 5000
      });

      test('should calculate fixed contract contribution correctly', () {
        final contract = _createFixedContract(
          id: 'netflix',
          status: ContractStatus.active,
          monthlyAmount: 649,
        );

        final snapshot = engine.executeMonth(
          contracts: [contract],
          month: 6,
          year: 2026,
        );

        expect(snapshot.fixedOutflow, 649);
        expect(snapshot.mandatoryOutflow, 649);
      });

      test('should aggregate all contract types correctly', () {
        final contracts = [
          _createReducingContract(
            id: 'loan',
            emiAmount: 15000,
            remainingBalance: 500000,
            interestRate: 10,
          ),
          _createGrowingContract(
            id: 'sip',
            monthlyAmount: 10000,
            totalInvested: 100000,
          ),
          _createFixedContract(id: 'subscription', monthlyAmount: 2000),
        ];

        final snapshot = engine.executeMonth(
          contracts: contracts,
          month: 6,
          year: 2026,
          totalIncome: 100000,
        );

        expect(snapshot.reducingOutflow, 15000);
        expect(snapshot.growingOutflow, 10000);
        expect(snapshot.fixedOutflow, 2000);
        expect(snapshot.mandatoryOutflow, 27000);
        expect(snapshot.freeBalance, 73000);
        expect(snapshot.activeContractCount, 3);
      });

      test('should calculate negative free balance correctly', () {
        final contracts = [
          _createReducingContract(emiAmount: 60000, remainingBalance: 1000000),
          _createGrowingContract(monthlyAmount: 30000),
          _createFixedContract(monthlyAmount: 20000),
        ];

        final snapshot = engine.executeMonth(
          contracts: contracts,
          month: 6,
          year: 2026,
          totalIncome: 80000,
        );

        expect(snapshot.mandatoryOutflow, 110000);
        expect(snapshot.freeBalance, -30000);
        expect(snapshot.isDeficit, true);
      });

      test('should throw error for invalid month', () {
        expect(
          () => engine.executeMonth(contracts: [], month: 0, year: 2026),
          throwsArgumentError,
        );

        expect(
          () => engine.executeMonth(contracts: [], month: 13, year: 2026),
          throwsArgumentError,
        );
      });
    });

    group('generateProjection', () {
      test('should generate correct number of snapshots', () {
        final projection = engine.generateProjection(
          contracts: [],
          startMonth: 1,
          startYear: 2026,
          monthCount: 12,
        );

        expect(projection.snapshots.length, 12);
        expect(projection.monthCount, 12);
      });

      test('should handle year rollover correctly', () {
        final projection = engine.generateProjection(
          contracts: [],
          startMonth: 11,
          startYear: 2025,
          monthCount: 4,
        );

        expect(projection.snapshots[0].month, 11);
        expect(projection.snapshots[0].year, 2025);
        expect(projection.snapshots[1].month, 12);
        expect(projection.snapshots[1].year, 2025);
        expect(projection.snapshots[2].month, 1);
        expect(projection.snapshots[2].year, 2026);
        expect(projection.snapshots[3].month, 2);
        expect(projection.snapshots[3].year, 2026);
      });

      test('should update reducing contract balance over time', () {
        final contract = _createReducingContract(
          id: 'loan',
          emiAmount: 10000,
          remainingBalance: 100000,
          interestRate: 12, // 1% monthly
        );

        final projection = engine.generateProjection(
          contracts: [contract],
          startMonth: 1,
          startYear: 2026,
          monthCount: 3,
        );

        // Month 1: Balance 100000, Interest 1000, Principal 9000, New 91000
        final month1 = projection.snapshots[0].contractBreakdown!.first;
        expect(month1.newBalance, 91000);

        // Month 2: Balance 91000, Interest 910, Principal 9090, New 81910
        final month2 = projection.snapshots[1].contractBreakdown!.first;
        expect(month2.newBalance, 81910);

        // Month 3: Balance 81910, Interest 819.10, Principal 9180.90, New 72729.10
        final month3 = projection.snapshots[2].contractBreakdown!.first;
        expect(month3.newBalance, closeTo(72729.1, 0.1));
      });

      test('should update growing contract invested amount over time', () {
        final contract = _createGrowingContract(
          id: 'sip',
          monthlyAmount: 5000,
          totalInvested: 10000,
        );

        final projection = engine.generateProjection(
          contracts: [contract],
          startMonth: 1,
          startYear: 2026,
          monthCount: 3,
        );

        expect(
          projection.snapshots[0].contractBreakdown!.first.newInvestedTotal,
          15000,
        );
        expect(
          projection.snapshots[1].contractBreakdown!.first.newInvestedTotal,
          20000,
        );
        expect(
          projection.snapshots[2].contractBreakdown!.first.newInvestedTotal,
          25000,
        );
      });

      test('should close loan when fully paid', () {
        final contract = _createReducingContract(
          id: 'loan',
          emiAmount: 10000,
          remainingBalance: 15000, // Small balance, will close soon
          interestRate: 12,
        );

        final projection = engine.generateProjection(
          contracts: [contract],
          startMonth: 1,
          startYear: 2026,
          monthCount: 3,
        );

        // Check final contract state - should be closed
        final finalLoan = projection.finalContractStates.firstWhere(
          (c) => c.id == 'loan',
        );
        expect(finalLoan.status, ContractStatus.closed);
      });

      test('should calculate projection totals correctly', () {
        final contract = _createFixedContract(monthlyAmount: 1000);

        final projection = engine.generateProjection(
          contracts: [contract],
          startMonth: 1,
          startYear: 2026,
          monthCount: 12,
          monthlyIncome: 50000,
        );

        expect(projection.totalMandatoryOutflow, 12000);
        expect(projection.totalIncome, 600000);
        expect(projection.totalFreeBalance, 588000);
        expect(projection.averageMonthlyOutflow, 1000);
      });
    });

    group('calculateTypeOutflow', () {
      test('should calculate total outflow for specific type', () {
        final contracts = [
          _createReducingContract(emiAmount: 10000, remainingBalance: 500000),
          _createGrowingContract(monthlyAmount: 5000),
          _createFixedContract(monthlyAmount: 2000),
        ];

        final reducingTotal = engine.calculateTypeOutflow(
          contracts: contracts,
          type: ContractType.reducing,
          startMonth: 1,
          startYear: 2026,
          monthCount: 6,
        );

        // 10000 * 6 months
        expect(reducingTotal, 60000);

        final growingTotal = engine.calculateTypeOutflow(
          contracts: contracts,
          type: ContractType.growing,
          startMonth: 1,
          startYear: 2026,
          monthCount: 6,
        );

        expect(growingTotal, 30000);
      });
    });
  });

  group('MonthlySnapshot', () {
    test('should calculate freeBalance correctly', () {
      final snapshot = MonthlySnapshot(
        month: 1,
        year: 2026,
        totalIncome: 100000,
        mandatoryOutflow: 60000,
        activeContractCount: 3,
        reducingOutflow: 30000,
        growingOutflow: 20000,
        fixedOutflow: 10000,
      );

      expect(snapshot.freeBalance, 40000);
      expect(snapshot.savingsRatePercent, 40.0);
      expect(snapshot.isDeficit, false);
    });

    test('should generate correct display month', () {
      final snapshot = MonthlySnapshot(
        month: 3,
        year: 2026,
        totalIncome: 0,
        mandatoryOutflow: 0,
        activeContractCount: 0,
        reducingOutflow: 0,
        growingOutflow: 0,
        fixedOutflow: 0,
      );

      expect(snapshot.monthName, 'March');
      expect(snapshot.displayMonth, 'March 2026');
    });

    test('should serialize and deserialize correctly', () {
      final original = MonthlySnapshot(
        month: 6,
        year: 2026,
        totalIncome: 150000,
        mandatoryOutflow: 75000,
        activeContractCount: 5,
        reducingOutflow: 40000,
        growingOutflow: 25000,
        fixedOutflow: 10000,
        generatedAt: DateTime(2026, 6, 1),
      );

      final json = original.toJson();
      final restored = MonthlySnapshot.fromJson(json);

      expect(restored.month, original.month);
      expect(restored.year, original.year);
      expect(restored.totalIncome, original.totalIncome);
      expect(restored.mandatoryOutflow, original.mandatoryOutflow);
      expect(restored.activeContractCount, original.activeContractCount);
      expect(restored.reducingOutflow, original.reducingOutflow);
      expect(restored.growingOutflow, original.growingOutflow);
      expect(restored.fixedOutflow, original.fixedOutflow);
    });

    test('should create empty snapshot correctly', () {
      final empty = MonthlySnapshot.empty(
        month: 1,
        year: 2026,
        totalIncome: 50000,
      );

      expect(empty.mandatoryOutflow, 0);
      expect(empty.activeContractCount, 0);
      expect(empty.freeBalance, 50000);
    });
  });

  group('Determinism', () {
    test('same inputs should always produce same output', () {
      final engine = const MonthlyExecutionEngine();
      final contracts = [
        _createReducingContract(
          id: 'loan',
          emiAmount: 15000,
          remainingBalance: 200000,
          interestRate: 10,
        ),
        _createGrowingContract(
          id: 'sip',
          monthlyAmount: 5000,
          totalInvested: 50000,
        ),
        _createFixedContract(id: 'sub', monthlyAmount: 1000),
      ];

      final snapshot1 = engine.executeMonth(
        contracts: contracts,
        month: 6,
        year: 2026,
        totalIncome: 100000,
      );

      final snapshot2 = engine.executeMonth(
        contracts: contracts,
        month: 6,
        year: 2026,
        totalIncome: 100000,
      );

      // All financial values should be identical
      expect(snapshot1.mandatoryOutflow, snapshot2.mandatoryOutflow);
      expect(snapshot1.reducingOutflow, snapshot2.reducingOutflow);
      expect(snapshot1.growingOutflow, snapshot2.growingOutflow);
      expect(snapshot1.fixedOutflow, snapshot2.fixedOutflow);
      expect(snapshot1.freeBalance, snapshot2.freeBalance);
      expect(snapshot1.activeContractCount, snapshot2.activeContractCount);
    });

    test('projections should be deterministic', () {
      final engine = const MonthlyExecutionEngine();
      final contracts = [
        _createReducingContract(
          id: 'loan',
          emiAmount: 10000,
          remainingBalance: 100000,
        ),
      ];

      final projection1 = engine.generateProjection(
        contracts: contracts,
        startMonth: 1,
        startYear: 2026,
        monthCount: 6,
        monthlyIncome: 50000,
      );

      final projection2 = engine.generateProjection(
        contracts: contracts,
        startMonth: 1,
        startYear: 2026,
        monthCount: 6,
        monthlyIncome: 50000,
      );

      expect(
        projection1.totalMandatoryOutflow,
        projection2.totalMandatoryOutflow,
      );
      expect(projection1.totalFreeBalance, projection2.totalFreeBalance);

      for (int i = 0; i < projection1.snapshots.length; i++) {
        expect(
          projection1.snapshots[i].mandatoryOutflow,
          projection2.snapshots[i].mandatoryOutflow,
        );
      }
    });
  });
}

// ============== Test Helpers ==============

Contract _createReducingContract({
  String id = 'reducing_test',
  ContractStatus status = ContractStatus.active,
  DateTime? startDate,
  DateTime? endDate,
  double emiAmount = 10000,
  double remainingBalance = 100000,
  double interestRate = 12,
}) {
  return Contract(
    id: id,
    name: 'Test Loan',
    type: ContractType.reducing,
    status: status,
    startDate: startDate ?? DateTime(2024, 1, 1),
    endDate: endDate,
    monthlyAmount: emiAmount,
    metadata: ReducingContractMetadata(
      principalAmount: remainingBalance,
      interestRatePercent: interestRate,
      tenureMonths: 120,
      remainingBalance: remainingBalance,
      emiAmount: emiAmount,
    ),
  );
}

Contract _createGrowingContract({
  String id = 'growing_test',
  ContractStatus status = ContractStatus.active,
  DateTime? startDate,
  double monthlyAmount = 5000,
  double totalInvested = 10000,
}) {
  return Contract(
    id: id,
    name: 'Test SIP',
    type: ContractType.growing,
    status: status,
    startDate: startDate ?? DateTime(2024, 1, 1),
    monthlyAmount: monthlyAmount,
    metadata: GrowingContractMetadata(
      currentValue: totalInvested * 1.1,
      totalInvested: totalInvested,
    ),
  );
}

Contract _createFixedContract({
  String id = 'fixed_test',
  ContractStatus status = ContractStatus.active,
  DateTime? startDate,
  double monthlyAmount = 649,
}) {
  return Contract(
    id: id,
    name: 'Test Subscription',
    type: ContractType.fixed,
    status: status,
    startDate: startDate ?? DateTime(2024, 1, 1),
    monthlyAmount: monthlyAmount,
    metadata: const FixedContractMetadata(billingCycle: BillingCycle.monthly),
  );
}
