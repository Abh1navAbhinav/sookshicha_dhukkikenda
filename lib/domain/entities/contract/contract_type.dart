/// Defines the behavior pattern of a contract over time.
///
/// Each type determines how the contract value or balance changes:
/// - [reducing]: Value decreases over time (loans, EMIs, mortgages)
/// - [growing]: Value increases over time (savings, investments, SIPs)
/// - [fixed]: Value remains constant (subscriptions, insurance, rent)
enum ContractType {
  /// Contract where the principal amount reduces over time.
  /// Examples: Home loan, Car loan, Personal loan, EMIs
  reducing('reducing'),

  /// Contract where the value grows or accumulates over time.
  /// Examples: Savings accounts, Mutual funds, SIPs, Fixed deposits
  growing('growing'),

  /// Contract with a fixed recurring amount that doesn't change.
  /// Examples: Netflix subscription, Insurance premium, Rent, Gym membership
  fixed('fixed');

  const ContractType(this.value);

  /// The string representation for JSON serialization
  final String value;

  /// Deserialize from JSON string
  static ContractType fromJson(String value) {
    return ContractType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown ContractType: $value'),
    );
  }

  /// Serialize to JSON string
  String toJson() => value;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case ContractType.reducing:
        return 'Reducing';
      case ContractType.growing:
        return 'Growing';
      case ContractType.fixed:
        return 'Fixed';
    }
  }

  /// Descriptive text for UI
  String get description {
    switch (this) {
      case ContractType.reducing:
        return 'Loans & EMIs - Balance decreases over time';
      case ContractType.growing:
        return 'Savings & Investments - Value grows over time';
      case ContractType.fixed:
        return 'Subscriptions & Insurance - Fixed recurring payments';
    }
  }
}
