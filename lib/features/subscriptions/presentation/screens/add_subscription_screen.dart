import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/components/sheets/app_sheet_container.dart';
import 'package:smartbudget/components/sheets/keyboard_aware_form_sheet.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

enum SubscriptionFormMode { create, update }

class AddSubscriptionScreen extends StatelessWidget {
  const AddSubscriptionScreen({
    super.key,
    this.asModal = false,
  });

  final bool asModal;

  @override
  Widget build(BuildContext context) {
    return SubscriptionFormSheet(
      mode: SubscriptionFormMode.create,
      asModal: asModal,
    );
  }
}

class SubscriptionFormSheet extends ConsumerStatefulWidget {
  const SubscriptionFormSheet({
    super.key,
    required this.mode,
    this.initialData,
    this.asModal = false,
  });

  final SubscriptionFormMode mode;
  final Subscription? initialData;
  final bool asModal;

  @override
  ConsumerState<SubscriptionFormSheet> createState() =>
      _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends ConsumerState<SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;
  bool _isAppBarScrolled = false;

  BillingCycle _billingCycle = BillingCycle.monthly;
  SubscriptionImportance _importance = SubscriptionImportance.medium;
  String _category = 'Streaming';
  DateTime _startDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now();
  bool _isActive = true;

  bool get _isUpdate => widget.mode == SubscriptionFormMode.update;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial == null) {
      return;
    }

    _nameController.text = initial.name;
    _amountController.text = initial.amount.toStringAsFixed(2);
    _paymentMethodController.text = initial.paymentMethod ?? '';
    _websiteController.text = initial.website ?? '';
    _notesController.text = initial.description ?? '';
    _billingCycle = initial.billingCycle;
    _importance = initial.importance;
    _category = initial.category;
    _startDate = initial.startDate;
    _nextBillingDate = initial.nextBillingDate;
    _isActive = initial.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  Future<void> _pickDate({required bool startDate}) async {
    final current = startDate ? _startDate : _nextBillingDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      if (startDate) {
        _startDate = picked;
        if (_nextBillingDate.isBefore(_startDate)) {
          _nextBillingDate = _startDate;
        }
      } else {
        _nextBillingDate = picked;
      }
    });
  }

  void _closeScreen() {
    if (widget.asModal) {
      Navigator.of(context).pop();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (GoRouter.of(context).canPop()) {
        context.pop();
        return;
      }
      context.go('/subscriptions');
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      AppFeedbackService.showWarning(
        context,
        'Complete required subscription fields to continue.',
      );
      return;
    }

    final parsedAmount = FormValidation.parseDecimal(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      AppFeedbackService.showWarning(
        context,
        'Enter a valid subscription amount greater than zero.',
      );
      return;
    }

    setState(() => _saving = true);
    AppFeedbackService.showLoading(
      context,
      _isUpdate ? 'Updating subscription...' : 'Saving subscription...',
    );

    try {
      final now = DateTime.now();
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final initial = widget.initialData;
      final subscription = Subscription(
        id: initial?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        amount: parsedAmount,
        currency: (initial?.currency ?? appCurrency).toUpperCase(),
        billingCycle: _billingCycle,
        startDate: _startDate,
        nextBillingDate: _nextBillingDate,
        category: _category,
        importance: _importance,
        isActive: _isActive,
        paymentMethod: _paymentMethodController.text.trim().isEmpty
            ? null
            : _paymentMethodController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        createdAt: initial?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(subscriptionListProvider.notifier);
      if (_isUpdate) {
        await notifier.updateSubscription(subscription);
      } else {
        await notifier.addSubscription(subscription);
      }

      if (!mounted) {
        return;
      }
      AppFeedbackService.showSuccess(
        context,
        _isUpdate
            ? 'Subscription updated successfully.'
            : 'Subscription added successfully.',
      );
      _closeScreen();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final fallbackError = 'Error saving subscription: $error';
      final message =
          l10n?.subscriptionsSaveError(error.toString()) ?? fallbackError;
      AppFeedbackService.showError(context, message);
    } finally {
      AppFeedbackService.dismissLoading();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final amount = FormValidation.parseDecimal(_amountController.text) ?? 0;
    final monthlyCost = _monthlyCostFor(
      amount: amount,
      cycle: _billingCycle,
    );

    final title = _isUpdate
        ? (l10n?.subscriptionsEditSubscription ?? 'Edit Subscription')
        : (l10n?.subscriptionsAddSubscription ?? 'Add Subscription');

    final categories = _categories(l10n);

    final formFields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.subscriptions_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.getFormat(appCurrency)
                            .format(monthlyCost),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_importance == SubscriptionImportance.critical) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2CC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                'Essential Subscription',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ModernInput(
            controller: _nameController,
            label: l10n?.subscriptionsName ?? 'Subscription Name',
            hintText: l10n?.subscriptionsNameHint ?? 'e.g., Netflix, Spotify',
            prefixIcon: Icons.label_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) => FormValidation.requiredText(
              value,
              l10n?.subscriptionsEnterName ??
                  'Please enter a subscription name',
            ),
          ),
          const SizedBox(height: 16),
          CurrencyInput(
            controller: _amountController,
            label: l10n?.amount ?? 'Amount',
            currencySymbol: CurrencyUtils.symbol(appCurrency),
            helperText: l10n?.subscriptionsPerMonth ?? 'per month',
            validator: (value) => FormValidation.positiveAmount(
              value,
              l10n?.subscriptionsRequired ?? 'Required',
              l10n?.subscriptionsInvalidAmount ?? 'Invalid amount',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          ModernDropdown<BillingCycle>(
            value: _billingCycle,
            label: l10n?.subscriptionsBillingCycle ?? 'Billing Cycle',
            prefixIcon: Icons.sync_rounded,
            items: BillingCycle.values
                .map(
                  (cycle) => DropdownMenuItem(
                    value: cycle,
                    child: Text(_cycleLabel(cycle, l10n)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _billingCycle = value);
              }
            },
          ),
          const SizedBox(height: 16),
          ModernDropdown<String>(
            value: _category,
            label: l10n?.category ?? 'Category',
            prefixIcon: Icons.category_rounded,
            searchable: true,
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 16),
          ModernDropdown<SubscriptionImportance>(
            value: _importance,
            label: l10n?.subscriptionsImportance ?? 'Importance',
            prefixIcon: Icons.priority_high_rounded,
            items: SubscriptionImportance.values
                .map(
                  (importance) => DropdownMenuItem(
                    value: importance,
                    child: Text(_importanceLabel(importance, l10n)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _importance = value);
              }
            },
          ),
          const SizedBox(height: 16),
          ModernDatePicker(
            label: l10n?.subscriptionsStartDate ?? 'Start Date',
            value: MaterialLocalizations.of(context).formatFullDate(_startDate),
            onTap: () => _pickDate(startDate: true),
          ),
          const SizedBox(height: 16),
          ModernDatePicker(
            label: l10n?.subscriptionsNextBillingLabel ?? 'Next Billing',
            value: MaterialLocalizations.of(context)
                .formatFullDate(_nextBillingDate),
            onTap: () => _pickDate(startDate: false),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _isActive,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Status',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(_isActive ? 'Active' : 'Paused'),
            onChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: 12),
          ModernInput(
            controller: _paymentMethodController,
            label: l10n?.subscriptionsPaymentMethod ?? 'Payment Method',
            hintText: l10n?.subscriptionsPaymentMethodHint ??
                'e.g., Credit Card, PayPal',
            prefixIcon: Icons.credit_card_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          ModernInput(
            controller: _websiteController,
            label: l10n?.subscriptionsWebsite ?? 'Website',
            hintText: l10n?.subscriptionsWebsiteHint ?? 'e.g., netflix.com',
            prefixIcon: Icons.public_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          ModernInput(
            controller: _notesController,
            label: l10n?.subscriptionsNotes ?? 'Notes',
            hintText: l10n?.subscriptionsNotesHint ??
                'Add any notes about this subscription',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.subscriptionsCostSummary ?? 'Cost Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n?.subscriptionsMonthlyCost ?? 'Monthly Cost'}: '
                  '${CurrencyUtils.getFormat(appCurrency).format(monthlyCost)}',
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n?.subscriptionsAnnualCost ?? 'Annual Cost'}: '
                  '${CurrencyUtils.getFormat(appCurrency).format(monthlyCost * 12)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final formBody = AppSheetContainer(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 108),
        child: formFields,
      ),
    );

    if (widget.asModal) {
      return KeyboardAwareFormSheet(
        onClose: _closeScreen,
        maxHeightFactor: 0.78,
        body: formFields,
        actions: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isUpdate ? Icons.check_rounded : Icons.add_rounded),
          label: Text(
            _isUpdate
                ? (l10n?.save ?? 'Save')
                : (l10n?.subscriptionsAdd ?? 'Add Subscription'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: title,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'subscription-form-appbar-blur-on',
          offKey: 'subscription-form-appbar-blur-off',
        ),
        leading: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
          ),
          icon: const Icon(Icons.close),
          onPressed: _closeScreen,
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: formBody,
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isUpdate ? Icons.check_rounded : Icons.add_rounded),
              label: Text(
                _isUpdate
                    ? (l10n?.save ?? 'Save')
                    : (l10n?.subscriptionsAdd ?? 'Add Subscription'),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _monthlyCostFor({
    required double amount,
    required BillingCycle cycle,
  }) {
    switch (cycle) {
      case BillingCycle.weekly:
        return amount * 4.33;
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.quarterly:
        return amount / 3;
      case BillingCycle.yearly:
        return amount / 12;
    }
  }

  String _cycleLabel(BillingCycle cycle, AppLocalizations? l10n) {
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n?.subscriptionsBillingWeekly ?? 'Weekly';
      case BillingCycle.monthly:
        return l10n?.subscriptionsBillingMonthly ?? 'Monthly';
      case BillingCycle.quarterly:
        return l10n?.subscriptionsBillingQuarterly ?? 'Quarterly';
      case BillingCycle.yearly:
        return l10n?.subscriptionsBillingYearly ?? 'Yearly';
    }
  }

  String _importanceLabel(
    SubscriptionImportance importance,
    AppLocalizations? l10n,
  ) {
    switch (importance) {
      case SubscriptionImportance.low:
        return l10n?.subscriptionsImportanceLow ?? 'Low - Optional';
      case SubscriptionImportance.medium:
        return l10n?.subscriptionsImportanceMedium ?? 'Medium - Regular use';
      case SubscriptionImportance.high:
        return l10n?.subscriptionsImportanceHigh ?? 'High - Important';
      case SubscriptionImportance.critical:
        return l10n?.subscriptionsImportanceCritical ?? 'Critical - Essential';
    }
  }

  List<String> _categories(AppLocalizations? l10n) {
    final values = [
      l10n?.subscriptionsCategoryStreaming ?? 'Streaming',
      l10n?.subscriptionsCategorySoftware ?? 'Software',
      l10n?.subscriptionsCategoryCloudStorage ?? 'Cloud Storage',
      l10n?.subscriptionsCategoryFitness ?? 'Fitness',
      l10n?.subscriptionsCategoryMusic ?? 'Music',
      l10n?.subscriptionsCategoryNews ?? 'News',
      l10n?.subscriptionsCategoryCommunication ?? 'Communication',
      l10n?.subscriptionsCategoryProductivity ?? 'Productivity',
      l10n?.subscriptionsCategoryEntertainment ?? 'Entertainment',
      l10n?.subscriptionsCategoryInsurance ?? 'Insurance',
      l10n?.subscriptionsCategoryUtilities ?? 'Utilities',
      l10n?.subscriptionsCategoryTransport ?? 'Transport',
      l10n?.subscriptionsCategoryHealth ?? 'Health',
      l10n?.subscriptionsCategoryOther ?? 'Other',
    ];

    if (_category.trim().isNotEmpty && !values.contains(_category)) {
      values.add(_category);
    }

    return values;
  }
}
