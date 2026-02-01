import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../domain/entities/contract/contract.dart';
import '../../domain/entities/contract/contract_type.dart';
import '../../injection.dart';
import '../bloc/add_contract/add_contract_cubit.dart';
import '../bloc/contract_detail/contract_detail_cubit.dart';
import '../bloc/contracts/contracts_cubit.dart';
import '../pages/contract_detail/contract_detail_screen.dart';
import '../pages/contracts/add_contract_screen.dart';
import '../theme/calm_theme.dart';
import 'amount_display.dart';
import 'calm_components.dart';

class ContractListItem extends StatelessWidget {
  const ContractListItem({
    required this.contract,
    this.isClosed = false,
    this.enableActions = true,
    this.showPinIndicator = true,
    super.key,
  });

  final Contract contract;
  final bool isClosed;
  final bool enableActions;
  final bool showPinIndicator;

  @override
  Widget build(BuildContext context) {
    // Inner card widget (the visual part)
    Widget card = CalmCard(
      onTap: () => _navigateToDetail(context, contract),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ContractTypeIcon(contract: contract, isClosed: isClosed),
              if (contract.showOnDashboard && showPinIndicator)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: CalmTheme.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 14,
                      color: CalmTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract.name,
                        style: CalmTheme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(switch (contract.type) {
                  ContractType.reducing => 'Pending Debt',
                  ContractType.growing => 'Total Invested',
                  ContractType.fixed =>
                    contract.fixedMetadata?.isLiability == true
                        ? 'Fixed Liability'
                        : 'Fixed Asset',
                }, style: CalmTheme.textTheme.bodySmall),
              ],
            ),
          ),
          AmountDisplay(
            amount: switch (contract.type) {
              ContractType.reducing => _calculateTotalPendingDebt(contract),
              ContractType.growing =>
                contract.growingMetadata?.totalInvested ?? 0.0,
              ContractType.fixed => contract.monthlyAmount,
            },
            size: AmountSize.compact,
            colorBased: false,
          ),
        ],
      ),
    );

    // If actions are disabled (e.g. simplified view), return just the card
    // However, the user asked for "same list tile" which includes actions in the list.
    // We'll wrap in Slidable unless explicitly disabled.
    // Note: Actions rely on ContractsCubit being in context.

    if (!enableActions) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Opacity(opacity: isClosed ? 0.6 : 1.0, child: card),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isClosed ? 0.6 : 1.0,
        child: Slidable(
          key: ValueKey(contract.id),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _onTogglePin(context),
                backgroundColor: CalmTheme.primary,
                foregroundColor: Colors.white,
                icon: contract.showOnDashboard
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                label: contract.showOnDashboard ? 'Unpin' : 'Pin',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.5,
            children: [
              SlidableAction(
                onPressed: (_) => _onEdit(context),
                backgroundColor: CalmTheme.primary,
                foregroundColor: Colors.white,
                icon: Icons.edit_rounded,
                label: 'Edit',
              ),
              SlidableAction(
                onPressed: (_) => _onDelete(context),
                backgroundColor: CalmTheme.danger,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Delete',
              ),
            ],
          ),
          child: card,
        ),
      ),
    );
  }

  void _onEdit(BuildContext parentContext) {
    Navigator.of(parentContext).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => sl<AddContractCubit>(),
          child: AddContractScreen(contract: contract),
        ),
      ),
    );
  }

  void _onDelete(BuildContext parentContext) async {
    // Check if ContractsCubit is available
    ContractsCubit cubit;
    try {
      cubit = parentContext.read<ContractsCubit>();
    } catch (e) {
      // If not available (e.g. dashboard), we might not support delete or should handle safely
      ScaffoldMessenger.of(
        parentContext,
      ).showSnackBar(const SnackBar(content: Text('Cannot delete from here')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contract'),
        content: Text('Are you sure you want to delete "${contract.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: CalmTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: CalmTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.deleteContract(contract.id);
    }
  }

  void _onTogglePin(BuildContext parentContext) {
    try {
      parentContext.read<ContractsCubit>().togglePin(contract);
    } catch (e) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Cannot pin/unpin from here')),
      );
    }
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

  double _calculateTotalPendingDebt(Contract contract) {
    if (contract.type != ContractType.reducing) return 0.0;

    final metadata = contract.reducingMetadata;
    if (metadata == null) return 0.0;

    // Calculate total pending based on remaining installments (Principal + Future Interest)
    // proportional to the agreed tenure.
    return metadata.remainingInstallments * metadata.emiAmount;
  }
}

class ContractTypeIcon extends StatelessWidget {
  const ContractTypeIcon({
    required this.contract,
    this.isClosed = false,
    super.key,
  });
  final Contract contract;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final type = contract.type;
    var (icon, color) = switch (type) {
      ContractType.reducing => (Icons.trending_down, CalmTheme.danger),
      ContractType.growing => (Icons.trending_up, CalmTheme.success),
      ContractType.fixed => (
        contract.fixedMetadata?.isLiability == true
            ? Icons.remove_circle_outline
            : Icons.add_circle_outline,
        CalmTheme.primary,
      ),
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
