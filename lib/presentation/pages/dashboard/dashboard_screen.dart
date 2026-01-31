import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/dashboard/dashboard_cubit.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/calm_components.dart';

/// Dashboard Screen
///
/// The main financial overview screen.
///
/// ## One Main Message
/// "Here's what you have left this month."
/// Everything else is secondary context.
///
/// ## Information Hierarchy
/// 1. **Free Balance** (HERO) - The one number that matters most
/// 2. **Income & Outflow** (Context) - How we got to free balance
/// 3. **Next 3 Months** (Forecast) - Quick look ahead
/// 4. **Active Contracts** (Action) - Link to manage contracts
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
          // App Bar with month
          SliverToBoxAdapter(
            child: _DashboardHeader(monthDisplay: state.monthDisplay),
          ),

          // Hero: Free Balance
          SliverToBoxAdapter(
            child: _FreeBalanceHero(
              freeBalance: state.freeBalance,
              isDeficit: state.isDeficit,
              healthStatus: state.healthStatus,
            ),
          ),

          // Income & Outflow Summary
          SliverToBoxAdapter(
            child: _IncomeOutflowSummary(
              income: state.income,
              outflow: state.mandatoryOutflow,
            ),
          ),

          // Next 3 Months Preview
          SliverToBoxAdapter(
            child: _MonthsPreview(snapshots: state.nextThreeMonths),
          ),

          // Contracts Summary
          SliverToBoxAdapter(
            child: _ContractsSummary(
              activeCount: state.activeContractsCount,
              upcomingContracts: state.upcomingContracts,
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

/// Dashboard Header
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.monthDisplay});

  final String monthDisplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
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
    );
  }
}

/// Hero: Free Balance
///
/// The most important number on the dashboard.
/// Large, color-coded, impossible to miss.
class _FreeBalanceHero extends StatelessWidget {
  const _FreeBalanceHero({
    required this.freeBalance,
    required this.isDeficit,
    required this.healthStatus,
  });

  final double freeBalance;
  final bool isDeficit;
  final DashboardHealthStatus healthStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CalmCard(
        backgroundColor: CalmTheme.getBalanceBackgroundColor(freeBalance),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              'Free Balance',
              style: CalmTheme.textTheme.labelLarge?.copyWith(
                color: CalmTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Amount (HERO)
            AmountDisplay(
              amount: freeBalance,
              size: AmountSize.hero,
              colorBased: true,
            ),

            const SizedBox(height: 16),

            // Health indicator
            _HealthIndicator(status: healthStatus),
          ],
        ),
      ),
    );
  }
}

/// Health Indicator
class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.status});

  final DashboardHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final (message, color) = switch (status) {
      DashboardHealthStatus.excellent => (
        'Excellent savings rate',
        CalmTheme.success,
      ),
      DashboardHealthStatus.good => (
        'Good financial health',
        CalmTheme.success,
      ),
      DashboardHealthStatus.fair => ('Room for improvement', CalmTheme.warning),
      DashboardHealthStatus.caution => (
        'Consider reducing expenses',
        CalmTheme.warning,
      ),
      DashboardHealthStatus.critical => (
        'Spending exceeds income',
        CalmTheme.danger,
      ),
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          message,
          style: CalmTheme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Income & Outflow Summary
class _IncomeOutflowSummary extends StatelessWidget {
  const _IncomeOutflowSummary({required this.income, required this.outflow});

  final double income;
  final double outflow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Income',
              amount: income,
              icon: Icons.arrow_downward_rounded,
              iconColor: CalmTheme.successMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryItem(
              label: 'Mandatory',
              amount: outflow,
              icon: Icons.arrow_upward_rounded,
              iconColor: CalmTheme.dangerMuted,
              isOutflow: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.isOutflow = false,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final bool isOutflow;

  @override
  Widget build(BuildContext context) {
    return CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(label, style: CalmTheme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          AmountDisplay(
            amount: isOutflow ? -amount : amount,
            size: AmountSize.small,
            colorBased: false,
          ),
        ],
      ),
    );
  }
}

/// Next 3 Months Preview
class _MonthsPreview extends StatelessWidget {
  const _MonthsPreview({required this.snapshots});

  final List<dynamic> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Looking Ahead',
            subtitle: 'Next 3 months projection',
          ),
          CalmCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < snapshots.length; i++) ...[
                  _MonthPreviewItem(
                    snapshot: snapshots[i],
                    isLast: i == snapshots.length - 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPreviewItem extends StatelessWidget {
  const _MonthPreviewItem({required this.snapshot, this.isLast = false});

  final dynamic snapshot;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // Handle both actual snapshots and placeholders
    final month = snapshot.month as int;
    final year = snapshot.year as int;
    final monthName = _getMonthName(month);

    // Try to get freeBalance, default to 0
    double freeBalance = 0;
    try {
      freeBalance = (snapshot.freeBalance as num?)?.toDouble() ?? 0;
    } catch (_) {
      freeBalance = 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: CalmTheme.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$monthName $year', style: CalmTheme.textTheme.bodyLarge),
          AmountDisplay(
            amount: freeBalance,
            size: AmountSize.compact,
            colorBased: true,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

/// Contracts Summary
class _ContractsSummary extends StatelessWidget {
  const _ContractsSummary({
    required this.activeCount,
    required this.upcomingContracts,
  });

  final int activeCount;
  final List<dynamic> upcomingContracts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Contracts',
            actionLabel: 'View All',
            onAction: () {
              // Navigate to contracts list
            },
          ),
          CalmCard(
            onTap: () {
              // Navigate to contracts list
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CalmTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: CalmTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$activeCount Active',
                        style: CalmTheme.textTheme.titleMedium,
                      ),
                      if (upcomingContracts.isNotEmpty)
                        Text(
                          '${upcomingContracts.length} expiring soon',
                          style: CalmTheme.textTheme.bodySmall?.copyWith(
                            color: CalmTheme.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: CalmTheme.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard Error State
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
