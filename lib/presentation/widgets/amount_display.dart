import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/calm_theme.dart';

/// Amount Display Widget
///
/// Displays monetary amounts with consistent formatting.
/// Large, clear typography for easy scanning.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    required this.amount,
    super.key,
    this.size = AmountSize.medium,
    this.showSign = false,
    this.showCurrency = true,
    this.colorBased = true,
    this.prefix,
    this.crossedOut = false,
  });

  /// The amount to display
  final double amount;

  /// Size variant
  final AmountSize size;

  /// Whether to show +/- sign
  final bool showSign;

  /// Whether to show currency symbol
  final bool showCurrency;

  /// Whether to color based on positive/negative
  final bool colorBased;

  /// Optional prefix text
  final String? prefix;

  /// Whether to show crossed out (for closed contracts)
  final bool crossedOut;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount();
    final textStyle = _getTextStyle();
    final color = colorBased ? CalmTheme.getBalanceColor(amount) : null;

    return Text(
      formattedAmount,
      style: textStyle.copyWith(
        color: color,
        decoration: crossedOut ? TextDecoration.lineThrough : null,
      ),
    );
  }

  String _formatAmount() {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: showCurrency ? '₹' : '',
      decimalDigits: 0,
    );

    final formatted = formatter.format(amount.abs());

    if (showSign && amount != 0) {
      return amount > 0 ? '+$formatted' : '-$formatted';
    }

    if (prefix != null) {
      return '$prefix$formatted';
    }

    return amount < 0 ? '-$formatted' : formatted;
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AmountSize.hero:
        return CalmTheme.textTheme.displayLarge!;
      case AmountSize.large:
        return CalmTheme.textTheme.displaySmall!;
      case AmountSize.medium:
        return CalmTheme.textTheme.headlineMedium!;
      case AmountSize.small:
        return CalmTheme.textTheme.titleLarge!;
      case AmountSize.compact:
        return CalmTheme.textTheme.titleMedium!;
    }
  }
}

enum AmountSize {
  hero, // Main dashboard number
  large, // Section totals
  medium, // Card amounts
  small, // List items
  compact, // Secondary info
}
