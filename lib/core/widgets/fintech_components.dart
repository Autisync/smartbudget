import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smartbudget/components/feedback/app_lottie_view.dart';
import 'package:smartbudget/core/theme/app_colors.dart';
import 'package:smartbudget/core/theme/app_icons.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          backgroundColor ?? (isDark ? null : const Color(0xFFF8F8FA)),
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
                color: resolvedTone.withValues(alpha: 0.12),
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
      color: tone.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
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
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
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
    this.moreTemporarilyActive = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool moreTemporarilyActive;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      moreTemporarilyActive: moreTemporarilyActive,
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
      child: child,
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
        color: color.withValues(alpha: 0.12),
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
                color: resolvedTone.withValues(alpha: 0.12),
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
              color: resolvedTone.withValues(alpha: 0.12),
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
              color: amountColor.withValues(alpha: 0.14),
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
    this.moreTemporarilyActive = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool moreTemporarilyActive;

  @override
  Widget build(BuildContext context) {
    const homeButtonSize = 60.0;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    const items = <_AppNavItemData>[
      _AppNavItemData(
        icon: AppIcons.transactions,
        activeIcon: AppIcons.transactionsFilled,
        label: 'Transactions',
        index: 0,
      ),
      _AppNavItemData(
        icon: AppIcons.budgets,
        activeIcon: AppIcons.budgetsFilled,
        label: 'Budgets',
        index: 1,
      ),
      _AppNavItemData(
        icon: AppIcons.homeOutline,
        activeIcon: AppIcons.home,
        label: '',
        index: 2,
      ),
      _AppNavItemData(
        icon: AppIcons.savings,
        activeIcon: AppIcons.savingsFilled,
        label: 'Savings',
        index: 3,
      ),
      _AppNavItemData(
        icon: AppIcons.moreGrid,
        activeIcon: AppIcons.moreGridFilled,
        label: 'More',
        index: 4,
      ),
    ];

    return SizedBox(
      height: 73 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav bar background and items
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 73 + bottomInset,
              padding: EdgeInsets.fromLTRB(12, 6, 12, 6 + bottomInset),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(UiTokens.radiusLg),
                ),
                // Subtle upward lift to separate the bar from scrolling content
                // without a heavy border or divider.
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: colorScheme.brightness == Brightness.dark
                          ? 0.22
                          : 0.05,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItemButton(
                    item: items[0],
                    selected: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavItemButton(
                    item: items[1],
                    selected: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  const SizedBox(
                      width: homeButtonSize), // Space for Home button
                  _NavItemButton(
                    item: items[3],
                    selected: currentIndex == 3,
                    onTap: () => onTabSelected(3),
                  ),
                  _NavItemButton(
                    item: items[4],
                    selected: moreTemporarilyActive || currentIndex == 4,
                    onTap: () => onTabSelected(4),
                  ),
                ],
              ),
            ),
          ),
          // Centered Home button, slightly lower and with shadow
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + bottomInset,
            child: Center(
              child: _HomeNavButton(
                icon: items[2].activeIcon,
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
                size: homeButtonSize,
              ),
            ),
          ),
        ],
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

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
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
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: UiTokens.motionFast,
                  curve: UiTokens.motionCurve,
                  scale: selected ? 1.06 : 1.0,
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 23,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: UiTokens.motionFast,
                  curve: UiTokens.motionCurve,
                  style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ) ??
                      TextStyle(
                        fontSize: 11,
                        height: 1,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavButton extends StatelessWidget {
  const _HomeNavButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Home',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: UiTokens.motionFast,
          curve: UiTokens.motionCurve,
          scale: selected ? 1.0 : 0.94,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.brandDeep, AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: colorScheme.onPrimary, size: 30),
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
                        color: Colors.white.withValues(alpha: 0.78),
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
                  color: Colors.white.withValues(alpha: 0.72),
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
      color: tone.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
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
          color: resolvedTone.withValues(alpha: 0.12),
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

class AppEmptyState extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              AppLottieView(
                assetPath: lottieAsset!,
                width: 108,
                height: 108,
                animate: true,
                repeat: false,
                semanticLabel: semanticLabel ?? '$title animation',
                fallbackIcon: icon,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(UiTokens.radiusXl),
                ),
                child: Icon(icon, size: 34, color: colorScheme.primary),
              ),
            const SizedBox(height: UiTokens.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: UiTokens.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: UiTokens.space20),
              action!,
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
      baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      highlightColor: colorScheme.surface.withValues(alpha: 0.90),
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
        color: color.withValues(alpha: 0.14),
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
                      .withValues(alpha: 0.4),
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
