import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:smartbudget/components/forms/financial_input.dart';
import 'package:smartbudget/components/forms/modern_select.dart';
import 'package:smartbudget/components/sheets/keyboard_aware_form_sheet.dart';
import 'package:smartbudget/core/theme/app_animations.dart';
import 'package:smartbudget/core/theme/app_spacing.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';

export 'package:smartbudget/core/widgets/fintech_components.dart'
    show AppCard, AppInsightCard, AppTransactionTile, AppBottomNavigation;
export 'package:smartbudget/components/feedback/app_feedback_service.dart';
export 'package:smartbudget/components/feedback/app_lottie_view.dart'
    show AppLottieView, AppLoadingState, AppSuccessState, AppErrorState;

class AppScaffold extends StatelessWidget {
  const AppScaffold({
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
    return SmartSpendScaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
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
    return SmartSpendHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
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
    return AppMetricCard(
      label: label,
      value: value,
      icon: icon,
      tone: tone,
      subtitle: subtitle,
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
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

enum AppButtonStyle { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = switch (style) {
      AppButtonStyle.primary => FilledButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon),
          label: Text(label),
        ),
      AppButtonStyle.secondary => OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon),
          label: Text(label),
        ),
      AppButtonStyle.danger => FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon),
          label: Text(label),
        ),
    };

    final effective = expand
        ? SizedBox(width: double.infinity, child: child)
        : IntrinsicWidth(child: child);

    return effective
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.emphasized)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.emphasized,
        );
  }
}

class AppInput extends ModernInput {
  const AppInput({
    super.key,
    required super.controller,
    required super.label,
    super.hintText,
    super.helperText,
    super.validator,
    super.keyboardType,
    super.prefixText,
    super.prefixIcon,
    super.suffixIcon,
    super.maxLines,
    super.onChanged,
    super.inputFormatters,
    super.textInputAction,
  });
}

class AppDropdown<T> extends ModernSelect<T> {
  const AppDropdown({
    super.key,
    required super.value,
    required super.label,
    required super.items,
    required super.onChanged,
    super.helperText,
    super.prefixIcon,
    super.searchable,
    super.searchHintText,
  });
}

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatShortDate(value),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.calendar_today_rounded, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.body,
    this.actions,
    this.onClose,
    this.maxHeightFactor = 0.78,
    this.bodyPadding = const EdgeInsets.fromLTRB(24, 12, 24, 12),
    this.showDragHandle = true,
    this.dismissOnBarrierTap = true,
  });

  final Widget body;
  final Widget? actions;
  final VoidCallback? onClose;
  final double maxHeightFactor;
  final EdgeInsetsGeometry bodyPadding;
  final bool showDragHandle;
  final bool dismissOnBarrierTap;

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareFormSheet(
      body: body,
      actions: actions,
      onClose: onClose,
      maxHeightFactor: maxHeightFactor,
      bodyPadding: bodyPadding,
      showDragHandle: showDragHandle,
      dismissOnBarrierTap: dismissOnBarrierTap,
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useRootNavigator = true,
  }) {
    return showCupertinoModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }
}

class AppSkeletonLoader extends StatelessWidget {
  const AppSkeletonLoader({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      child: child,
    );
  }
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.assetName,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final String assetName;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeader(title: title, subtitle: subtitle),
        const Gap(AppSpacing.md),
        child,
      ],
    );
  }
}
