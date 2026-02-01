import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../injection.dart';
import '../../bloc/add_contract/add_contract_barrel.dart';
import '../../bloc/contract_detail/contract_detail_barrel.dart';
import '../../bloc/contracts/contracts_cubit.dart';
import '../../bloc/contracts/contracts_state.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/calm_components.dart';
import '../contract_detail/contract_detail_screen.dart';
import 'add_contract_screen.dart';

/// Contracts List Screen - Simple, scannable list of all contracts
class ContractsListScreen extends StatefulWidget {
  const ContractsListScreen({super.key});

  @override
  State<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends State<ContractsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContractsCubit>().watchContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalmTheme.background,
      body: SafeArea(
        child: BlocBuilder<ContractsCubit, ContractsState>(
          builder: (context, state) {
            return switch (state) {
              ContractsInitial() => const CalmLoading(),
              ContractsLoading() => const CalmLoading(message: 'Loading...'),
              ContractsLoaded() => _ContractsContent(state: state),
              ContractsError() => _ErrorView(message: state.message),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContract(context),
        backgroundColor: CalmTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToAddContract(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<AddContractCubit>(),
          child: const AddContractScreen(),
        ),
      ),
    );
  }
}

class _ContractsContent extends StatelessWidget {
  const _ContractsContent({required this.state});
  final ContractsLoaded state;

  @override
  Widget build(BuildContext context) {
    final allFiltered = state.filteredContracts;
    final openContracts = allFiltered.where((c) => !c.isClosed).toList();
    final closedContracts = allFiltered.where((c) => c.isClosed).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<ContractsCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _Header()),
          // Filter chips
          SliverToBoxAdapter(child: _FilterChips(state: state)),
          // Summary
          SliverToBoxAdapter(
            child: _Summary(
              total: openContracts.length,
              outflow: state.totalMonthlyOutflow,
            ),
          ),
          // Open Contracts List
          if (openContracts.isEmpty && closedContracts.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(message: 'No contracts'),
            )
          else ...[
            if (openContracts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ContractItem(contract: openContracts[i]),
                    childCount: openContracts.length,
                  ),
                ),
              ),

            // Closed Contracts Section
            if (closedContracts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: SectionHeader(
                    title: 'Closed',
                    subtitle:
                        '${closedContracts.length} ${closedContracts.length == 1 ? 'contract' : 'contracts'}',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ContractItem(
                      contract: closedContracts[i],
                      isClosed: true,
                    ),
                    childCount: closedContracts.length,
                  ),
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Text('Contracts', style: CalmTheme.textTheme.headlineLarge),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});
  final ContractsLoaded state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          for (final type in ContractType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: type.displayName,
                selected: state.filterType == type,
                onTap: () => context.read<ContractsCubit>().filterByType(
                  state.filterType == type ? null : type,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CalmTheme.primary : CalmTheme.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : CalmTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.outflow});
  final int total;
  final double outflow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: CalmCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$total Active', style: CalmTheme.textTheme.titleMedium),
            AmountDisplay(
              amount: outflow,
              size: AmountSize.medium,
              colorBased: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractItem extends StatelessWidget {
  const _ContractItem({required this.contract, this.isClosed = false});
  final Contract contract;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isClosed ? 0.6 : 1.0,
      child: CalmCard(
        margin: const EdgeInsets.only(bottom: 12),
        onTap: () => _navigateToDetail(context, contract),
        child: Row(
          children: [
            _TypeIcon(type: contract.type, isClosed: isClosed),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contract.name, style: CalmTheme.textTheme.titleMedium),
                  Text(
                    contract.type.displayName,
                    style: CalmTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AmountDisplay(
              amount: contract.monthlyAmount,
              size: AmountSize.compact,
              colorBased: !isClosed,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Contract contract) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<ContractDetailCubit>()),
          ],
          child: ContractDetailScreen(contractId: contract.id),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, this.isClosed = false});
  final ContractType type;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    var (icon, color) = switch (type) {
      ContractType.reducing => (Icons.trending_down, CalmTheme.danger),
      ContractType.growing => (Icons.trending_up, CalmTheme.success),
      ContractType.fixed => (Icons.horizontal_rule, CalmTheme.primary),
    };

    if (isClosed) {
      color = CalmTheme.textMuted;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      message: message,
      actionLabel: 'Retry',
      onAction: () => context.read<ContractsCubit>().loadContracts(),
    );
  }
}
