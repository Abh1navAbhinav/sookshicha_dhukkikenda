/// Represents the lifecycle state of a contract.
///
/// A contract moves through states:
/// - [active]: Currently running and being tracked
/// - [paused]: Temporarily suspended (e.g., payment holiday)
/// - [closed]: Completed or terminated
enum ContractStatus {
  /// Contract is currently active and being tracked.
  /// Monthly calculations and updates are performed.
  active('active'),

  /// Contract is temporarily paused.
  /// No monthly updates during this period.
  /// Examples: EMI moratorium, subscription pause, investment freeze
  paused('paused'),

  /// Contract has been closed/completed.
  /// No further updates will be made.
  /// Examples: Loan fully paid, subscription cancelled, investment matured
  closed('closed');

  const ContractStatus(this.value);

  /// The string representation for JSON serialization
  final String value;

  /// Deserialize from JSON string
  static ContractStatus fromJson(String value) {
    return ContractStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown ContractStatus: $value'),
    );
  }

  /// Serialize to JSON string
  String toJson() => value;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.paused:
        return 'Paused';
      case ContractStatus.closed:
        return 'Closed';
    }
  }

  /// Whether this status allows monthly updates
  bool get allowsUpdates {
    switch (this) {
      case ContractStatus.active:
        return true;
      case ContractStatus.paused:
      case ContractStatus.closed:
        return false;
    }
  }

  /// Whether this is a terminal state
  bool get isTerminal => this == ContractStatus.closed;
}
