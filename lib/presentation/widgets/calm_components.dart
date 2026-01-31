import 'package:flutter/material.dart';

import '../theme/calm_theme.dart';

/// Calm Card Widget
///
/// A minimal, soft card component for content grouping.
/// Uses subtle shadows and generous padding for breathing room.
class CalmCard extends StatelessWidget {
  const CalmCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevated = false,
  });

  /// Card content
  final Widget? child;

  /// Custom padding (defaults to theme card padding)
  final EdgeInsets? padding;

  /// Margin around the card
  final EdgeInsets? margin;

  /// Tap callback
  final VoidCallback? onTap;

  /// Background color override
  final Color? backgroundColor;

  /// Border color (adds subtle border)
  final Color? borderColor;

  /// Whether to use elevated shadow
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? CalmTheme.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? CalmTheme.cardBackground,
        borderRadius: BorderRadius.circular(CalmTheme.radiusLg),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: elevated ? CalmTheme.elevatedShadow : CalmTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CalmTheme.radiusLg),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// Status Pill Widget
///
/// Small, soft pill for status indicators.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    super.key,
    this.color,
    this.textColor,
    this.icon,
  });

  /// Status label text
  final String label;

  /// Background color
  final Color? color;

  /// Text color
  final Color? textColor;

  /// Optional leading icon
  final IconData? icon;

  /// Factory constructors for common statuses
  factory StatusPill.active() => StatusPill(
    label: 'Active',
    color: CalmTheme.successLight,
    textColor: CalmTheme.success,
  );

  factory StatusPill.paused() => StatusPill(
    label: 'Paused',
    color: CalmTheme.warningLight,
    textColor: CalmTheme.warning,
  );

  factory StatusPill.closed() => StatusPill(
    label: 'Closed',
    color: CalmTheme.divider,
    textColor: CalmTheme.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? CalmTheme.primaryLight,
        borderRadius: BorderRadius.circular(CalmTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? CalmTheme.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: CalmTheme.textTheme.labelMedium?.copyWith(
              color: textColor ?? CalmTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget
///
/// Clean section title with optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  /// Section title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Action widget (overrides actionLabel/onAction)
  final Widget? action;

  /// Action button label
  final String? actionLabel;

  /// Action callback
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CalmTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CalmTheme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: CalmTheme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null)
            action!
          else if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Empty State Widget
///
/// Calm, encouraging empty state message.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.icon,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  /// Main message
  final String message;

  /// Icon to display
  final IconData? icon;

  /// Custom action widget
  final Widget? action;

  /// Action button label
  final String? actionLabel;

  /// Action callback
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: CalmTheme.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 64, color: CalmTheme.textHint),
              const SizedBox(height: CalmTheme.spacingLg),
            ],
            Text(
              message,
              style: CalmTheme.textTheme.bodyLarge?.copyWith(
                color: CalmTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: CalmTheme.spacingXl),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: CalmTheme.spacingXl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading Indicator Widget
///
/// Calm, minimal loading state.
class CalmLoading extends StatelessWidget {
  const CalmLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CalmTheme.primary.withValues(alpha: 0.6),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: CalmTheme.spacingLg),
            Text(
              message!,
              style: CalmTheme.textTheme.bodyMedium?.copyWith(
                color: CalmTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress Bar Widget
///
/// Soft, animated progress indicator.
class CalmProgress extends StatelessWidget {
  const CalmProgress({
    required this.value,
    super.key,
    this.height = 8,
    this.backgroundColor,
    this.foregroundColor,
    this.label,
  });

  /// Progress value (0-1)
  final double value;

  /// Bar height
  final double height;

  /// Background color
  final Color? backgroundColor;

  /// Foreground (fill) color
  final Color? foregroundColor;

  /// Optional label below
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? CalmTheme.divider,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: foregroundColor ?? CalmTheme.primary,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label!, style: CalmTheme.textTheme.labelSmall),
        ],
      ],
    );
  }
}
