import 'package:equatable/equatable.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_status.dart';
import '../../../domain/entities/contract/contract_type.dart';

/// Contracts List State
///
/// Manages the state for the contracts list screen.
/// Supports filtering, grouping, and search functionality.
sealed class ContractsState extends Equatable {
  const ContractsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class ContractsInitial extends ContractsState {
  const ContractsInitial();
}

/// Loading state
final class ContractsLoading extends ContractsState {
  const ContractsLoading();
}

/// Loaded state with all contract data
final class ContractsLoaded extends ContractsState {
  const ContractsLoaded({
    required this.allContracts,
    this.filterType,
    this.filterStatus,
    this.searchQuery,
  });

  /// All contracts (unfiltered)
  final List<Contract> allContracts;

  /// Current type filter (null = all types)
  final ContractType? filterType;

  /// Current status filter (null = all statuses)
  final ContractStatus? filterStatus;

  /// Current search query
  final String? searchQuery;

  // ============== Computed Properties ==============

  /// Filtered contracts based on current filters
  List<Contract> get filteredContracts {
    var result = allContracts;

    // Apply type filter
    if (filterType != null) {
      result = result.where((c) => c.type == filterType).toList();
    }

    // Apply status filter
    if (filterStatus != null) {
      result = result.where((c) => c.status == filterStatus).toList();
    }

    // Apply search
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  /// Contracts grouped by type
  Map<ContractType, List<Contract>> get contractsByType {
    final grouped = <ContractType, List<Contract>>{};
    for (final contract in filteredContracts) {
      grouped.putIfAbsent(contract.type, () => []).add(contract);
    }
    return grouped;
  }

  /// Contracts grouped by status
  Map<ContractStatus, List<Contract>> get contractsByStatus {
    final grouped = <ContractStatus, List<Contract>>{};
    for (final contract in filteredContracts) {
      grouped.putIfAbsent(contract.status, () => []).add(contract);
    }
    return grouped;
  }

  /// Active contracts only
  List<Contract> get activeContracts {
    return allContracts.where((c) => c.isActive).toList();
  }

  /// Total monthly outflow from active contracts
  double get totalMonthlyOutflow {
    return activeContracts.fold(0, (sum, c) => sum + c.monthlyAmount);
  }

  /// Count by type
  Map<ContractType, int> get countByType {
    final counts = <ContractType, int>{};
    for (final contract in allContracts) {
      counts[contract.type] = (counts[contract.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Whether any filters are active
  bool get hasActiveFilters =>
      filterType != null ||
      filterStatus != null ||
      (searchQuery?.isNotEmpty ?? false);

  /// Copy with new filters
  ContractsLoaded copyWith({
    List<Contract>? allContracts,
    ContractType? filterType,
    ContractStatus? filterStatus,
    String? searchQuery,
    bool clearTypeFilter = false,
    bool clearStatusFilter = false,
    bool clearSearch = false,
  }) {
    return ContractsLoaded(
      allContracts: allContracts ?? this.allContracts,
      filterType: clearTypeFilter ? null : (filterType ?? this.filterType),
      filterStatus: clearStatusFilter
          ? null
          : (filterStatus ?? this.filterStatus),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [
    allContracts,
    filterType,
    filterStatus,
    searchQuery,
  ];
}

/// Error state
final class ContractsError extends ContractsState {
  const ContractsError({required this.message, this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}
