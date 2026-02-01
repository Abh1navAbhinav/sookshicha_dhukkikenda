import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/entities/snapshot/monthly_snapshot.dart';
import '../../../injection.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/contracts/contracts_barrel.dart';
import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/calm_components.dart';
import '../contracts/contracts_list_screen.dart';

/// Dashboard Screen
///
/// Improved financial overview with charts and insights.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalmTheme.background,
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return switch (state) {
              DashboardInitial() => const CalmLoading(),
              DashboardLoading() => const CalmLoading(message: 'Loading...'),
              DashboardLoaded() => _DashboardContent(state: state),
              DashboardError() => _DashboardError(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      color: CalmTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _DashboardHeader(monthDisplay: state.monthDisplay),
          ),

          // Total Investment & Pending Debt (Primary Metrics)
          SliverToBoxAdapter(
            child: _FinancialHighLevelSummary(
              totalInvestment: state.totalInvestment,
              totalPendingDebt: state.totalPendingDebt,
            ),
          ),

          // Chart Section
          if (state.chartProjections.isNotEmpty)
            SliverToBoxAdapter(
              child: _DebtIncomeChart(projections: state.chartProjections),
            ),

          // Insights Section
          if (state.financialInsights.isNotEmpty)
            SliverToBoxAdapter(
              child: _FinancialInsights(insights: state.financialInsights),
            ),

          // Pinned Contracts Section
          if (state.pinnedContracts.isNotEmpty)
            SliverToBoxAdapter(
              child: _PinnedContracts(contracts: state.pinnedContracts),
            ),

          // All Contracts Link
          SliverToBoxAdapter(
            child: _ContractsLink(
              activeCount: state.activeContractsCount,
              upcomingContractsCount: state.upcomingContracts.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: CalmTheme.spacingXxl),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.monthDisplay});

  final String monthDisplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthDisplay, style: CalmTheme.textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Financial Overview',
                style: CalmTheme.textTheme.bodyLarge?.copyWith(
                  color: CalmTheme.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: Icon(Icons.logout_rounded, color: CalmTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _FinancialHighLevelSummary extends StatelessWidget {
  const _FinancialHighLevelSummary({
    required this.totalInvestment,
    required this.totalPendingDebt,
  });

  final double totalInvestment;
  final double totalPendingDebt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: CalmCard(
              backgroundColor: CalmTheme.successLight.withValues(alpha: 0.3),
              borderColor: CalmTheme.success.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL INVESTMENT',
                    style: CalmTheme.textTheme.labelSmall?.copyWith(
                      color: CalmTheme.success,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactInteractiveAmount(
                    amount: totalInvestment,
                    label: 'Total Investment',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CalmCard(
              backgroundColor: CalmTheme.dangerLight.withValues(alpha: 0.3),
              borderColor: CalmTheme.danger.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PENDING DEBT',
                    style: CalmTheme.textTheme.labelSmall?.copyWith(
                      color: CalmTheme.danger,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactInteractiveAmount(
                    amount: totalPendingDebt,
                    label: 'Pending Debt',
                    colorBased: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInteractiveAmount extends StatelessWidget {
  const _CompactInteractiveAmount({
    required this.amount,
    required this.label,
    this.colorBased = true,
  });

  final double amount;
  final String label;
  final bool colorBased;

  String _formatCompact(double value) {
    if (value == 0) return '₹0';
    final absValue = value.abs();

    if (absValue >= 1000000000) {
      return '₹${(absValue / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}B';
    } else if (absValue >= 1000000) {
      return '₹${(absValue / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (absValue >= 1000) {
      return '₹${(absValue / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
    }

    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatCompact(amount);
    final color = colorBased ? CalmTheme.getBalanceColor(amount) : null;

    return InkWell(
      onTap: () => _showFullAmount(context),
      borderRadius: BorderRadius.circular(4),
      child: Text(
        formatted,
        style: CalmTheme.textTheme.displaySmall!.copyWith(color: color),
      ),
    );
  }

  void _showFullAmount(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CalmTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: CalmTheme.textTheme.titleMedium?.copyWith(
                  color: CalmTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              AmountDisplay(
                amount: amount,
                size: AmountSize.hero,
                colorBased: colorBased,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CalmTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtIncomeChart extends StatelessWidget {
  const _DebtIncomeChart({required this.projections});

  final List<MonthlySnapshot> projections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Forecast',
            subtitle: 'Net Worth Projection (12 Months)',
          ),
          CalmCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 220,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: CalmTheme.textTheme.bodySmall,
                  iconHeight: 12,
                  iconWidth: 12,
                ),
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: CalmTheme.textTheme.bodySmall,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: true,
                  majorGridLines: MajorGridLines(
                    width: 1,
                    dashArray: [5, 5],
                    color: CalmTheme.textMuted.withValues(alpha: 0.2),
                  ),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: CalmTheme.textTheme.bodySmall?.copyWith(
                    color: CalmTheme.textMuted,
                    fontSize: 10,
                  ),
                  majorTickLines: const MajorTickLines(size: 0),
                  numberFormat: NumberFormat.compact(locale: 'en_IN'),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  canShowMarker: false,
                  format: 'point.x : point.y',
                  textStyle: CalmTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                series: <CartesianSeries<MonthlySnapshot, String>>[
                  ColumnSeries<MonthlySnapshot, String>(
                    dataSource: projections,
                    xValueMapper: (MonthlySnapshot s, _) =>
                        s.monthName.substring(0, 3),
                    yValueMapper: (MonthlySnapshot s, _) => s.totalWealth,
                    name: 'Total Wealth',
                    color: CalmTheme.success,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    width: 0.6,
                    spacing: 0.2,
                  ),
                  ColumnSeries<MonthlySnapshot, String>(
                    dataSource: projections,
                    xValueMapper: (MonthlySnapshot s, _) =>
                        s.monthName.substring(0, 3),
                    yValueMapper: (MonthlySnapshot s, _) => s.totalDebt,
                    name: 'Remaining Debt',
                    color: CalmTheme.danger,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    width: 0.6,
                    spacing: 0.2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialInsights extends StatelessWidget {
  const _FinancialInsights({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Review & Insights'),
          CalmCard(
            backgroundColor: CalmTheme.primaryLight.withValues(alpha: 0.2),
            child: Column(
              children: insights.map((insight) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: CalmTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
                          style: CalmTheme.textTheme.bodyMedium?.copyWith(
                            color: CalmTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedContracts extends StatelessWidget {
  const _PinnedContracts({required this.contracts});

  final List<Contract> contracts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Pinned Contracts',
            subtitle: 'Important commitments at a glance',
          ),
          ...contracts.map(
            (contract) => _PinnedContractItem(contract: contract),
          ),
        ],
      ),
    );
  }
}

class _PinnedContractItem extends StatelessWidget {
  const _PinnedContractItem({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    return CalmCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        // Navigate to detail? Or just show info
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: contract.type == ContractType.reducing
                  ? CalmTheme.dangerLight
                  : CalmTheme.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              contract.type == ContractType.reducing
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: contract.type == ContractType.reducing
                  ? CalmTheme.danger
                  : CalmTheme.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contract.name, style: CalmTheme.textTheme.titleSmall),
                Text(
                  contract.type.displayName,
                  style: CalmTheme.textTheme.bodySmall?.copyWith(
                    color: CalmTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AmountDisplay(
            amount: contract.monthlyAmount,
            size: AmountSize.compact,
            colorBased: false,
          ),
        ],
      ),
    );
  }
}

class _ContractsLink extends StatelessWidget {
  const _ContractsLink({
    required this.activeCount,
    required this.upcomingContractsCount,
  });

  final int activeCount;
  final int upcomingContractsCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CalmCard(
        onTap: () => _navigateToContracts(context),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CalmTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined, color: CalmTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage All Contracts',
                    style: CalmTheme.textTheme.titleMedium,
                  ),
                  Text(
                    '$activeCount Active • $upcomingContractsCount Expiring Soon',
                    style: CalmTheme.textTheme.bodySmall?.copyWith(
                      color: CalmTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: CalmTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _navigateToContracts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<ContractsCubit>(),
          child: const ContractsListScreen(),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.state});

  final DashboardError state;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      message: state.message,
      actionLabel: state.canRetry ? 'Try Again' : null,
      onAction: state.canRetry
          ? () => context.read<DashboardCubit>().loadDashboard()
          : null,
    );
  }
}
