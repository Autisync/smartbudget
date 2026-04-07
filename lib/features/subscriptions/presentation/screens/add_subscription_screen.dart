import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/input_styles.dart';
import 'package:smartbudget/core/widgets/form_date_field.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/data/models/tables.dart'
    show BillingCycle, SubscriptionImportance;
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/core/widgets/branded_title.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? existingSubscription;

  const AddSubscriptionScreen({super.key, this.existingSubscription});

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isAppBarScrolled = false;
  bool _isSaving = false;

  late String _category;
  late BillingCycle _billingCycle;
  late SubscriptionImportance _importance;
  late DateTime _startDate;
  late DateTime _nextBillingDate;

  static const List<String> _defaultCategories = [
    'Streaming',
    'Software',
    'Cloud Storage',
    'Fitness',
    'Music',
    'News',
    'Communication',
    'Productivity',
    'Entertainment',
    'Insurance',
    'Utilities',
    'Transport',
    'Health',
    'Other',
  ];

  String _getCategoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Streaming':
        return l10n.subscriptionsCategoryStreaming;
      case 'Software':
        return l10n.subscriptionsCategorySoftware;
      case 'Cloud Storage':
        return l10n.subscriptionsCategoryCloudStorage;
      case 'Fitness':
        return l10n.subscriptionsCategoryFitness;
      case 'Music':
        return l10n.subscriptionsCategoryMusic;
      case 'News':
        return l10n.subscriptionsCategoryNews;
      case 'Communication':
        return l10n.subscriptionsCategoryCommunication;
      case 'Productivity':
        return l10n.subscriptionsCategoryProductivity;
      case 'Entertainment':
        return l10n.subscriptionsCategoryEntertainment;
      case 'Insurance':
        return l10n.subscriptionsCategoryInsurance;
      case 'Utilities':
        return l10n.subscriptionsCategoryUtilities;
      case 'Transport':
        return l10n.subscriptionsCategoryTransport;
      case 'Health':
        return l10n.subscriptionsCategoryHealth;
      case 'Other':
        return l10n.subscriptionsCategoryOther;
      default:
        return category;
    }
  }

  @override
  void initState() {
    super.initState();
    final sub = widget.existingSubscription;
    if (sub != null) {
      _nameController.text = sub.name;
      _amountController.text = sub.amount.toString();
      _descriptionController.text = sub.description ?? '';
      _paymentMethodController.text = sub.paymentMethod ?? '';
      _websiteController.text = sub.website ?? '';
      _category = sub.category;
      _billingCycle = sub.billingCycle;
      _importance = sub.importance;
      _startDate = sub.startDate;
      _nextBillingDate = sub.nextBillingDate;
    } else {
      _category = 'Streaming';
      _billingCycle = BillingCycle.monthly;
      _importance = SubscriptionImportance.medium;
      _startDate = DateTime.now();
      _nextBillingDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _paymentMethodController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  double get _monthlyCost {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    switch (_billingCycle) {
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

  double get _annualCost {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    switch (_billingCycle) {
      case BillingCycle.weekly:
        return amount * 52;
      case BillingCycle.monthly:
        return amount * 12;
      case BillingCycle.quarterly:
        return amount * 4;
      case BillingCycle.yearly:
        return amount;
    }
  }

  String _getImportanceLabel(
      AppLocalizations l10n, SubscriptionImportance importance) {
    switch (importance) {
      case SubscriptionImportance.low:
        return l10n.subscriptionsImportanceLow;
      case SubscriptionImportance.medium:
        return l10n.subscriptionsImportanceMedium;
      case SubscriptionImportance.high:
        return l10n.subscriptionsImportanceHigh;
      case SubscriptionImportance.critical:
        return l10n.subscriptionsImportanceCritical;
    }
  }

  Color _getImportanceColor(SubscriptionImportance importance) {
    switch (importance) {
      case SubscriptionImportance.low:
        return Colors.blue;
      case SubscriptionImportance.medium:
        return Colors.orange;
      case SubscriptionImportance.high:
        return Colors.deepOrange;
      case SubscriptionImportance.critical:
        return Colors.red;
    }
  }

  String _getBillingCycleLabel(AppLocalizations l10n, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n.subscriptionsBillingWeekly;
      case BillingCycle.monthly:
        return l10n.subscriptionsBillingMonthly;
      case BillingCycle.quarterly:
        return l10n.subscriptionsBillingQuarterly;
      case BillingCycle.yearly:
        return l10n.subscriptionsBillingYearly;
    }
  }

  void _closeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (GoRouter.of(context).canPop()) {
        context.pop();
        return;
      }
      context.go('/subscriptions');
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final appCurrency = ref.read(appCurrencyControllerProvider);

      final subscription = Subscription(
        id: widget.existingSubscription?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: appCurrency,
        billingCycle: _billingCycle,
        startDate: _startDate,
        nextBillingDate: _nextBillingDate,
        category: _category,
        importance: _importance,
        paymentMethod: _paymentMethodController.text.trim().isEmpty
            ? null
            : _paymentMethodController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        isActive: true,
        createdAt: widget.existingSubscription?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.existingSubscription == null) {
          await ref
              .read(subscriptionListProvider.notifier)
              .addSubscription(subscription);
        } else {
          await ref
              .read(subscriptionListProvider.notifier)
              .updateSubscription(subscription);
        }

        if (mounted) {
          _closeScreen();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.subscriptionsSaveError(
                  e.toString(),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingSubscription != null;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final currencyFormat = NumberFormat.currency(symbol: '');

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : colorScheme.surface,
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: BrandedTitle(
            label: isEditing
                ? l10n.subscriptionsEditSubscription
                : l10n.subscriptionsAddSubscription,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isAppBarScrolled
                  ? ClipRect(
                      key: const ValueKey('subscription-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('subscription-appbar-blur-off'),
                    ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : _closeScreen,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: Text(l10n.transactionsSaveTransaction),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            _updateAppBarScrollState(notification.metrics.pixels);
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription name
                  TextFormField(
                    controller: _nameController,
                    style: InputStyles.inputTextStyle(Theme.of(context)),
                    decoration: InputDecoration(
                      labelText: l10n.subscriptionsName,
                      hintText: l10n.subscriptionsNameHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.subscriptionsEnterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category and Amount row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;

                      final categoryField = DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _category,
                        icon: InputStyles.dropdownIcon(context),
                        decoration: InputDecoration(
                          labelText: l10n.category,
                        ),
                        items: _defaultCategories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_getCategoryLabel(l10n, c)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      );

                      final amountField = TextFormField(
                        controller: _amountController,
                        style: InputStyles.inputTextStyle(Theme.of(context)),
                        decoration: InputDecoration(
                          labelText: l10n.amount,
                          prefixText: '${CurrencyUtils.symbol(appCurrency)} ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.subscriptionsRequired;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.subscriptionsInvalidAmount;
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            categoryField,
                            const SizedBox(height: 12),
                            amountField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: categoryField),
                          const SizedBox(width: 12),
                          Expanded(child: amountField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Billing cycle and importance
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;

                      final cycleField = DropdownButtonFormField<BillingCycle>(
                        isExpanded: true,
                        initialValue: _billingCycle,
                        icon: InputStyles.dropdownIcon(context),
                        decoration: InputDecoration(
                          labelText: l10n.subscriptionsBillingCycle,
                        ),
                        items: BillingCycle.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_getBillingCycleLabel(l10n, c)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _billingCycle = value);
                          }
                        },
                      );

                      final importanceField =
                          DropdownButtonFormField<SubscriptionImportance>(
                        isExpanded: true,
                        initialValue: _importance,
                        icon: InputStyles.dropdownIcon(context),
                        decoration: InputDecoration(
                          labelText: l10n.subscriptionsImportance,
                        ),
                        items: SubscriptionImportance.values
                            .map((imp) => DropdownMenuItem(
                                  value: imp,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getImportanceColor(imp),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_getImportanceLabel(l10n, imp)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        selectedItemBuilder: (_) =>
                            SubscriptionImportance.values
                                .map((imp) => Text(
                                      _getImportanceLabel(l10n, imp),
                                      overflow: TextOverflow.ellipsis,
                                    ))
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importance = value);
                          }
                        },
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            cycleField,
                            const SizedBox(height: 12),
                            importanceField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cycleField),
                          const SizedBox(width: 12),
                          Expanded(child: importanceField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Cost summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: InputStyles.costSummaryDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.subscriptionsCostSummary,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.subscriptionsMonthlyCost,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(_monthlyCost),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.subscriptionsAnnualCost,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(_annualCost),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.secondary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Importance info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: InputStyles.importanceBannerDecoration(
                      _getImportanceColor(_importance),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getImportanceColor(_importance),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getImportanceLabel(l10n, _importance),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _getImportanceColor(_importance),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start date and next billing date
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 560;

                      Widget buildDateButton({
                        required VoidCallback onPressed,
                        required String label,
                        required String value,
                      }) {
                        return FormDateField(
                          label: label,
                          value: value,
                          onTap: onPressed,
                        );
                      }

                      final startButton = buildDateButton(
                        onPressed: () async {
                          final pick = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (pick != null) {
                            setState(() => _startDate = pick);
                          }
                        },
                        label: l10n.subscriptionsStartDate,
                        value: DateFormat('MMM dd, yyyy').format(_startDate),
                      );

                      final nextButton = buildDateButton(
                        onPressed: () async {
                          final pick = await showDatePicker(
                            context: context,
                            initialDate: _nextBillingDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2050),
                          );
                          if (pick != null) {
                            setState(() => _nextBillingDate = pick);
                          }
                        },
                        label: l10n.subscriptionsNextBillingLabel,
                        value:
                            DateFormat('MMM dd, yyyy').format(_nextBillingDate),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            SizedBox(
                                width: double.infinity, child: startButton),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: nextButton),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: startButton),
                          const SizedBox(width: 12),
                          Expanded(child: nextButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Optional fields section
                  Text(
                    l10n.subscriptionsOptionalDetails,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Payment method
                  TextFormField(
                    controller: _paymentMethodController,
                    style: InputStyles.inputTextStyle(Theme.of(context)),
                    decoration: InputDecoration(
                      labelText: l10n.subscriptionsPaymentMethod,
                      hintText: l10n.subscriptionsPaymentMethodHint,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Website
                  TextFormField(
                    controller: _websiteController,
                    style: InputStyles.inputTextStyle(Theme.of(context)),
                    decoration: InputDecoration(
                      labelText: l10n.subscriptionsWebsite,
                      hintText: l10n.subscriptionsWebsiteHint,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: InputStyles.inputTextStyle(Theme.of(context)),
                    decoration: InputDecoration(
                      labelText: l10n.subscriptionsNotes,
                      hintText: l10n.subscriptionsNotesHint,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Decision helper section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.subscriptionsDecisionHelp,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDecisionHelper(context, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionHelper(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final annualCost = _annualCost;
    String suggestion = '';
    IconData icon = Icons.info;
    Color color = colorScheme.outline;

    if (annualCost == 0) {
      suggestion = l10n.subscriptionsDecisionEnterAmount;
    } else if (annualCost > 500) {
      suggestion = l10n.subscriptionsDecisionHighAnnualCost(
        annualCost.toStringAsFixed(0),
      );
      color = Colors.red;
      icon = Icons.warning;
    } else if (annualCost > 200) {
      suggestion = l10n.subscriptionsDecisionModerateAnnualCost(
        annualCost.toStringAsFixed(0),
      );
      color = Colors.orange;
      icon = Icons.info_outline;
    } else {
      suggestion = l10n.subscriptionsDecisionTrackRegularly;
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            suggestion,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
