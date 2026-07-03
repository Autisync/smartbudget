import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/app_icons.dart';
import 'package:smartbudget/core/theme/app_shadows.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

const BoxShadow _smartShadow = BoxShadow(
  color: Color.fromRGBO(0, 0, 0, 0.04),
  blurRadius: 18,
  offset: Offset(0, 6),
);

class SmartSpendScaffold extends StatelessWidget {
  const SmartSpendScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Inherit the themed scaffold background by default so every screen
      // shares one canvas color instead of a per-screen near-match hex.
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

class SmartCard extends StatelessWidget {
  const SmartCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [_smartShadow],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SmartMetricTile extends StatelessWidget {
  const SmartMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final resolvedTone = tone ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [_smartShadow],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: resolvedTone.withOpacity( 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: resolvedTone, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SmartInsightCard extends StatelessWidget {
  const SmartInsightCard({
    super.key,
    required this.title,
    required this.explanation,
    required this.impact,
    required this.action,
    required this.badge,
    required this.tone,
    this.icon = Icons.insights_rounded,
  });

  final String title;
  final String explanation;
  final String impact;
  final String action;
  final String badge;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SmartCard(
      radius: 28,
      color: tone.withOpacity( 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withOpacity( 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              AppBadge(label: badge, color: tone),
            ],
          ),
          const SizedBox(height: 12),
          Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(impact, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(action, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class SmartGradientButton extends StatelessWidget {
  const SmartGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDeep, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [_smartShadow],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class SmartOutlinedButton extends StatelessWidget {
  const SmartOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class SmartInputField extends StatelessWidget {
  const SmartInputField({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class SmartProgressBar extends StatelessWidget {
  const SmartProgressBar({
    super.key,
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedFinanceProgressBar(
      value: value,
      color: color,
      height: 7,
      backgroundColor:
          Theme.of(context).colorScheme.outlineVariant.withOpacity( 0.35),
    );
  }
}

class SmartEmptyState extends StatelessWidget {
  const SmartEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.lottieAsset,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final String? lottieAsset;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      action: action,
      lottieAsset: lottieAsset,
    );
  }
}

class SmartActionSheet extends StatelessWidget {
  const SmartActionSheet({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppActionSheet(title: title, children: children);
  }
}

class SmartBottomNav extends StatelessWidget {
  const SmartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onActionButtonTapped,
    this.actionIsClose = false,
    this.moreActive = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onActionButtonTapped;
  final bool actionIsClose;
  final bool moreActive;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      onActionButtonTapped: onActionButtonTapped,
      actionIsClose: actionIsClose,
      moreActive: moreActive,
    );
  }
}

class SmartSpendHeader extends StatelessWidget {
  const SmartSpendHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(UiTokens.space20),
    this.onTap,
    this.radius = UiTokens.radiusXl,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: AppSurfaces.elevated(
        context,
        radius: radius,
        color: color,
      ),
      // Transparent Material below the colored decoration so ListTile /
      // SwitchListTile descendants paint ink/background correctly (Flutter 3.44
      // asserts when a tile sits in a colored box with no Material between).
      child: Material(type: MaterialType.transparency, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(UiTokens.space20),
    this.onTap,
    this.radius = UiTokens.radiusXl,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      onTap: onTap,
      radius: radius,
      color: color,
      child: child,
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: UiTokens.space12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: UiTokens.space4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: UiTokens.space12),
          trailing!,
        ],
      ],
    );
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: UiTokens.space4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedTone = tone ?? colorScheme.primary;
    return AppCard(
      padding: const EdgeInsets.all(UiTokens.space16),
      radius: UiTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: resolvedTone.withOpacity( 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: resolvedTone),
            ),
          if (icon != null) const SizedBox(height: UiTokens.space12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: UiTokens.space8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: UiTokens.space4),
            Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class AppInsightCard extends StatelessWidget {
  const AppInsightCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.tone,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedTone = tone ?? colorScheme.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(UiTokens.space16),
      radius: UiTokens.radiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: resolvedTone.withOpacity( 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: resolvedTone),
          ),
          const SizedBox(width: UiTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: UiTokens.space4),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: UiTokens.space8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppTransactionTile extends StatelessWidget {
  const AppTransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: UiTokens.radiusLg,
      padding: const EdgeInsets.all(UiTokens.space12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: amountColor.withOpacity( 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: amountColor, size: 22),
          ),
          const SizedBox(width: UiTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: UiTokens.space4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: UiTokens.space8),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppStatGrid extends StatelessWidget {
  const AppStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: UiTokens.space8,
      runSpacing: UiTokens.space8,
      children: children,
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onActionButtonTapped,
    this.actionIsClose = false,
    this.moreActive = false,
    this.capsuleVisible = true,
  });

  final int currentIndex;

  /// Invoked with the destination index for the four capsule items
  /// (Transactions, Home, Savings, More).
  final ValueChanged<int> onTabSelected;

  /// Invoked when the detached round button is tapped. It opens the quick-add
  /// menu, or closes whichever menu is currently open (when [actionIsClose]).
  final VoidCallback onActionButtonTapped;

  /// When true the round button shows "×" (a menu is open) instead of "+".
  final bool actionIsClose;

  /// Highlights the "More" capsule item while its menu is open.
  final bool moreActive;

  /// When false the main capsule is hidden, leaving only the detached round
  /// button visible (used while an expandable menu is open).
  final bool capsuleVisible;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    // Four focused destinations live inside the floating capsule; Budgets and
    // Subscriptions now live under More. The detached "+" circle to the right
    // opens the quick-add menu. Indices match the router's semantic scheme
    // (0 Transactions, 1 Home, 2 Savings, 3 More).
    final items = <_AppNavItemData>[
      _AppNavItemData(
        icon: AppIcons.homeOutline,
        activeIcon: AppIcons.home,
        label: l10n.navHome,
        index: 1,
      ),
      _AppNavItemData(
        icon: AppIcons.transactions,
        activeIcon: AppIcons.transactionsFilled,
        label: l10n.transactionsTitle,
        index: 0,
      ),
      _AppNavItemData(
        icon: AppIcons.savings,
        activeIcon: AppIcons.savingsFilled,
        label: l10n.navSavings,
        index: 2,
      ),
      _AppNavItemData(
        icon: AppIcons.moreGrid,
        activeIcon: AppIcons.moreGridFilled,
        label: l10n.navMore,
        index: 3,
      ),
    ];

    const barHeight = 60.0;
    // Near-transparent, frosted fill so the screen shows through the bar.
    final capsuleColor =
        colorScheme.surface.withOpacity( isDark ? 0.55 : 0.6);
    final floatShadow = AppShadows.floating(colorScheme.shadow);
    final hairline = colorScheme.outline.withOpacity( isDark ? 0.55 : 0.9);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 8),
      child: Row(
        children: [
          // Main capsule with the five destinations. Hidden (and ignoring
          // input) while an expandable menu is open, leaving just the round ×.
          Expanded(
            child: IgnorePointer(
              ignoring: !capsuleVisible,
              child: AnimatedOpacity(
                duration: UiTokens.motionFast,
                curve: UiTokens.motionCurve,
                opacity: capsuleVisible ? 1 : 0,
                child: _FrostedSurface(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  color: capsuleColor,
                  borderColor: hairline,
                  shadow: floatShadow,
                  child: SizedBox(
                    height: barHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          for (final item in items)
                            Expanded(
                              child: _CapsuleNavItem(
                                item: item,
                                selected: item.index == 3
                                    ? (moreActive || currentIndex == 3)
                                    : currentIndex == item.index,
                                onTap: () => onTabSelected(item.index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Detached circular action button (morphs + ↔ ×).
          _PlusNavButton(
            active: actionIsClose,
            size: barHeight,
            onTap: onActionButtonTapped,
          ),
        ],
      ),
    );
  }
}

/// A frosted-glass surface: a near-transparent fill with a backdrop blur so
/// content shows through, a hairline border, and a soft drop shadow kept
/// outside the clip. Used by the floating nav capsule and action button.
class _FrostedSurface extends StatelessWidget {
  const _FrostedSurface({
    required this.borderRadius,
    required this.color,
    required this.borderColor,
    required this.shadow,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Color color;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppNavItemData {
  const _AppNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
}

/// A single icon destination inside the floating nav capsule. The active item
/// gets a soft filled pill behind a filled-variant icon (matching the
/// reference); inactive items are muted outline icons.
class _CapsuleNavItem extends StatelessWidget {
  const _CapsuleNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AppNavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    // Active pill uses primaryContainer so it matches the action panel tiles.
    final pillColor = isDark
        ? colorScheme.primaryContainer.withOpacity( 0.45)
        : colorScheme.primaryContainer.withOpacity( 0.70);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          // Pill height is always 44 dp so it never overflows the 60dp capsule
          // (which has 8dp vertical padding on each side = 44dp content area).
          // The label animates in below the icon INSIDE the fixed-height pill.
          child: AnimatedContainer(
            duration: UiTokens.motionFast,
            curve: UiTokens.motionCurve,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? pillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                // Label slides in under the active icon without changing pill
                // height — AnimatedSize collapses to zero for inactive items.
                AnimatedSize(
                  duration: UiTokens.motionFast,
                  curve: UiTokens.motionCurve,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              height: 1.0,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detached circular button beside the capsule. Shows a "+" that morphs to "×"
/// while the expandable action menu is open.
class _PlusNavButton extends StatelessWidget {
  const _PlusNavButton({
    required this.active,
    required this.size,
    required this.onTap,
  });

  final bool active;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: active ? 'Close menu' : 'Open add menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _FrostedSurface(
          borderRadius: BorderRadius.circular(size / 2),
          color: colorScheme.surface.withOpacity( isDark ? 0.55 : 0.6),
          borderColor:
              colorScheme.outline.withOpacity( isDark ? 0.55 : 0.9),
          shadow: AppShadows.floating(colorScheme.shadow),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              // Cross-fade between add and close icons so the shape is always
              // unambiguous — a rotated "+" can look like a diamond, not a ×.
              child: AnimatedSwitcher(
                duration: UiTokens.motionMedium,
                switchInCurve: UiTokens.motionCurve,
                switchOutCurve: UiTokens.motionCurve.flipped,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  active ? Icons.close_rounded : Icons.add_rounded,
                  key: ValueKey(active),
                  size: 26,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label != null && label!.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

class AppProgressSection extends StatelessWidget {
  const AppProgressSection({
    super.key,
    required this.title,
    required this.progress,
    required this.color,
    this.subtitle,
  });

  final String title;
  final double progress;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(UiTokens.space16),
      radius: UiTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: UiTokens.space4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: UiTokens.space12),
          AnimatedFinanceProgressBar(
            value: progress,
            color: color,
          ),
        ],
      ),
    );
  }
}

class AppFinancialBanner extends StatelessWidget {
  const AppFinancialBanner({
    super.key,
    required this.title,
    required this.value,
    required this.supportingText,
    this.trailing,
  });

  final String title;
  final String value;
  final String supportingText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UiTokens.space20),
      decoration: AppSurfaces.heroCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity( 0.78),
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: UiTokens.space12),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: UiTokens.space8),
          Text(
            supportingText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity( 0.72),
                ),
          ),
        ],
      ),
    );
  }
}

class AppAlertCard extends StatelessWidget {
  const AppAlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final String message;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: UiTokens.radiusLg,
      padding: const EdgeInsets.all(UiTokens.space16),
      color: tone.withOpacity( 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withOpacity( 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(width: UiTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: UiTokens.space4),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppSummaryPanel extends StatelessWidget {
  const AppSummaryPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: UiTokens.radiusXl,
      padding: const EdgeInsets.all(UiTokens.space16),
      child: Wrap(
        spacing: UiTokens.space12,
        runSpacing: UiTokens.space12,
        children: children,
      ),
    );
  }
}

class AppInfoTile extends StatelessWidget {
  const AppInfoTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: UiTokens.radiusLg,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing,
      ),
    );
  }
}

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedTone = tone ?? colorScheme.primary;
    return AppInfoTile(
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 18),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: resolvedTone.withOpacity( 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: resolvedTone),
      ),
    );
  }
}

class FinanceAmount extends StatelessWidget {
  const FinanceAmount({
    super.key,
    required this.value,
    this.color,
    this.compact = false,
    this.textAlign,
  });

  final String value;
  final Color? color;
  final bool compact;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.headlineMedium;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class AppEmptyState extends StatefulWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.lottieAsset,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final String? lottieAsset;
  final String? semanticLabel;

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
    final titleAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.70, curve: Curves.easeOut));
    final bodyAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.42, 0.85, curve: Curves.easeOut));
    final actionAnim = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.58, 1.00, curve: Curves.easeOut));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — scales in + floats continuously
            AnimatedBuilder(
              animation: Listenable.merge([iconAnim, _floatCtrl]),
              builder: (context, _) {
                final floatY = (_floatCtrl.value * 2 - 1) * 5;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.scale(
                    scale: iconAnim.value,
                    child: Opacity(
                      opacity: iconAnim.value.clamp(0.0, 1.0),
                      child: widget.lottieAsset != null
                          ? AppLottieView(
                              assetPath: widget.lottieAsset!,
                              width: 200,
                              height: 200,
                              animate: true,
                              repeat: true,
                              semanticLabel: widget.semanticLabel ??
                                  '${widget.title} animation',
                              fallbackIcon: widget.icon,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withOpacity( 0.10),
                                borderRadius:
                                    BorderRadius.circular(UiTokens.radiusXl),
                              ),
                              child: Icon(widget.icon,
                                  size: 38, color: colorScheme.primary),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: UiTokens.space16),
            // Title
            AnimatedBuilder(
              animation: titleAnim,
              builder: (context, child) => Opacity(
                opacity: titleAnim.value,
                child: Transform.translate(
                    offset: Offset(0, 14 * (1 - titleAnim.value)),
                    child: child),
              ),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: UiTokens.space8),
            // Message
            AnimatedBuilder(
              animation: bodyAnim,
              builder: (context, child) => Opacity(
                opacity: bodyAnim.value,
                child: Transform.translate(
                    offset: Offset(0, 10 * (1 - bodyAnim.value)),
                    child: child),
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (widget.action != null) ...[
              const SizedBox(height: UiTokens.space20),
              AnimatedBuilder(
                animation: actionAnim,
                builder: (context, child) => Opacity(
                  opacity: actionAnim.value,
                  child: Transform.translate(
                      offset: Offset(0, 8 * (1 - actionAnim.value)),
                      child: child),
                ),
                child: widget.action!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppCurrencyText extends StatelessWidget {
  const AppCurrencyText({
    super.key,
    required this.value,
    this.color,
    this.large = false,
    this.textAlign,
  });

  final String value;
  final Color? color;
  final bool large;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FinanceAmount(
      value: value,
      color: color,
      compact: !large,
      textAlign: textAlign,
    );
  }
}

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 120,
    this.radius = UiTokens.radiusXl,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withOpacity( 0.55),
      highlightColor: colorScheme.surface.withOpacity( 0.90),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: UiTokens.space4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class AppActionSheet extends StatelessWidget {
  const AppActionSheet(
      {super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity( 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: UiTokens.space16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: UiTokens.space16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AnimatedFinanceProgressBar extends StatelessWidget {
  const AnimatedFinanceProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 9,
  });

  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final trackColor = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: safeValue),
      duration: UiTokens.motionMedium,
      curve: UiTokens.motionCurve,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: height,
            color: color,
            backgroundColor: trackColor,
          ),
        );
      },
    );
  }
}

class CircularFinanceProgress extends StatelessWidget {
  const CircularFinanceProgress({
    super.key,
    required this.value,
    required this.color,
    required this.center,
    this.size = 92,
    this.strokeWidth = 8,
  });

  final double value;
  final Color color;
  final Widget center;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final trackColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: safeValue),
            duration: UiTokens.motionMedium,
            curve: UiTokens.motionCurve,
            builder: (context, animatedValue, _) {
              return CircularProgressIndicator(
                value: animatedValue,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: trackColor,
              );
            },
          ),
          center,
        ],
      ),
    );
  }
}
