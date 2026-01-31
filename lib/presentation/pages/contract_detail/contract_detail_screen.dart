import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/contract/contract_type.dart';
import '../../bloc/contract_detail/contract_detail_cubit.dart';
import '../../bloc/contract_detail/contract_detail_state.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/calm_components.dart';

/// Contract Detail Screen
///
/// One contract, one focus. All details about a single commitment.
///
/// ## One Main Message
/// "Here's everything about this contract."
///
/// ## Information Hierarchy
/// 1. Name & Status (Identity)
/// 2. Monthly Amount (Core Metric)
/// 3. Type-Specific Details (Context)
/// 4. Actions (Pause/Close)
class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({required this.contractId, super.key});

  final String contractId;

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContractDetailCubit>().loadContract(widget.contractId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalmTheme.background,
      body: SafeArea(
        child: BlocConsumer<ContractDetailCubit, ContractDetailState>(
          listener: (context, state) {
            if (state is ContractDetailActionCompleted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contract ${state.action.name}')),
              );
            }
          },
          builder: (context, state) {
            return switch (state) {
              ContractDetailInitial() => const CalmLoading(),
              ContractDetailLoading() => const CalmLoading(),
              ContractDetailLoaded() => _DetailContent(state: state),
              ContractDetailError() => _ErrorView(message: state.message),
              ContractDetailActionCompleted() => const CalmLoading(),
            };
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Back button & title
            SliverToBoxAdapter(child: _Header(name: state.name)),
            // Status & Type
            SliverToBoxAdapter(child: _StatusRow(state: state)),
            // Monthly Amount Card
            SliverToBoxAdapter(child: _AmountCard(amount: state.monthlyAmount)),
            // Details based on type
            SliverToBoxAdapter(child: _TypeDetails(state: state)),
            // Prepayment option for loans
            if (state.contract.type == ContractType.reducing && state.isActive)
              SliverToBoxAdapter(child: _PrepaymentActions(state: state)),
            // Timeline info
            SliverToBoxAdapter(child: _TimelineInfo(state: state)),
            // Actions
            SliverToBoxAdapter(child: _Actions(state: state)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        // Loading overlay
        if (state.isUpdating)
          Container(color: Colors.black12, child: const CalmLoading()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: CalmTheme.textTheme.headlineSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _TypeBadge(type: state.contract.type),
          const SizedBox(width: 8),
          if (!state.isActive) _StatusBadge(status: state.statusDisplay),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ContractType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ContractType.reducing => ('Loan/EMI', CalmTheme.danger),
      ContractType.growing => ('Investment', CalmTheme.success),
      ContractType.fixed => ('Subscription', CalmTheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CalmTheme.warningLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(status, style: TextStyle(color: CalmTheme.warning)),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: CalmCard(
        backgroundColor: CalmTheme.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Amount', style: CalmTheme.textTheme.labelLarge),
            const SizedBox(height: 8),
            AmountDisplay(
              amount: amount,
              size: AmountSize.large,
              colorBased: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeDetails extends StatelessWidget {
  const _TypeDetails({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    // Reducing (Loan) details
    if (state.reducingDetails != null) {
      final d = state.reducingDetails!;
      return _DetailsCard(
        title: 'Loan Details',
        items: [
          ('Original Principal', _formatCurrency(d.principalAmount)),
          ('Total Paid', _formatCurrency(d.totalPaid)),
          ('Remaining Balance', _formatCurrency(d.remainingBalance)),
          ('Interest Rate', '${d.interestRate}%'),
          ('Progress', '${d.progressPercent.toStringAsFixed(1)}%'),
        ],
        progress: d.progressPercent / 100,
        extra: Column(
          children: [
            const Divider(height: 32),
            _InfoRow('Monthly Interest', _formatCurrency(d.interestPortion)),
            _InfoRow('Monthly Principal', _formatCurrency(d.principalPortion)),
            Text(
              'This month\'s split',
              style: CalmTheme.textTheme.bodySmall?.copyWith(
                color: CalmTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    // Growing (Investment) details
    if (state.growingDetails != null) {
      final d = state.growingDetails!;
      return _DetailsCard(
        title: 'Investment Details',
        items: [
          ('Total Invested', _formatCurrency(d.invested)),
          ('Current Value', _formatCurrency(d.currentValue)),
          ('Returns', '${d.returnsPercent.toStringAsFixed(1)}%'),
        ],
      );
    }
    // Fixed (Subscription) details
    if (state.fixedDetails != null) {
      final d = state.fixedDetails!;
      return _DetailsCard(
        title: 'Subscription Details',
        items: [
          ('Category', d.category),
          ('Billing', d.billingCycle),
          ('Auto Renew', d.autoRenew ? 'Yes' : 'No'),
          ('Total Paid', _formatCurrency(d.totalPaid)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(value);
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.items,
    this.progress,
    this.extra,
  });
  final String title;
  final List<(String, String)> items;
  final double? progress;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CalmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CalmTheme.textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.$1, style: CalmTheme.textTheme.bodyMedium),
                    Text(item.$2, style: CalmTheme.textTheme.titleSmall),
                  ],
                ),
              ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              CalmProgress(value: progress!),
            ],
            ?extra,
          ],
        ),
      ),
    );
  }
}

class _TimelineInfo extends StatelessWidget {
  const _TimelineInfo({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');
    DateTime endDate = state.endDate ?? state.startDate;
    int monthsLeft = state.monthsRemaining ?? 0;

    if (state.contract.type == ContractType.reducing) {
      final rd = state.reducingDetails;
      if (rd != null) {
        monthsLeft = rd.projectedRemainingMonths;
        // Project logical end date from current month + remaining months
        final now = DateTime.now();
        endDate = DateTime(now.year, now.month + monthsLeft);
      }
    } else if (state.endDate == null) {
      endDate = state.startDate;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: CalmCard(
        child: Column(
          children: [
            _InfoRow('Started', dateFormat.format(state.startDate)),
            _InfoRow('Ends', dateFormat.format(endDate)),
            _InfoRow('Months Elapsed', '${state.monthsElapsed}'),
            if (monthsLeft > 0) _InfoRow('Months Left', '$monthsLeft'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CalmTheme.textTheme.bodyMedium),
          Text(value, style: CalmTheme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _PrepaymentActions extends StatelessWidget {
  const _PrepaymentActions({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            context,
            icon: Icons.add_card_rounded,
            label: 'Make Prepayment',
            onTap: () => _showAmountDialog(context),
            color: CalmTheme.primary,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.check_circle_outline_rounded,
            label: 'Settle Loan Fully',
            onTap: () => _showSettleDialog(context),
            color: CalmTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CalmTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAmountDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prepayment Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter amount',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                context.read<ContractDetailCubit>().makePrepayment(amount);
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showSettleDialog(BuildContext context) {
    final balance = state.reducingDetails?.remainingBalance ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Loan?'),
        content: Text(
          'This will close the loan by paying the remaining balance of ₹${balance.toInt().toString()}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CalmTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContractDetailCubit>().makePrepayment(balance);
            },
            child: const Text('Confirm Settlement'),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state});
  final ContractDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.contract.isClosed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isActive)
            OutlinedButton(
              onPressed: () =>
                  context.read<ContractDetailCubit>().pauseContract(),
              child: const Text('Pause Contract'),
            )
          else if (state.isPaused)
            ElevatedButton(
              onPressed: () =>
                  context.read<ContractDetailCubit>().resumeContract(),
              child: const Text('Resume Contract'),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showCloseDialog(context),
            style: TextButton.styleFrom(foregroundColor: CalmTheme.danger),
            child: const Text('Close Contract'),
          ),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Contract?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContractDetailCubit>().closeContract();
            },
            style: TextButton.styleFrom(foregroundColor: CalmTheme.danger),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: Icons.error_outline, message: message);
  }
}
