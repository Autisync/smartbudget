import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/data/models/tables.dart'
    show BillingCycle, SubscriptionImportance;
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
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

  String _getImportanceLabel(SubscriptionImportance importance) {
    switch (importance) {
      case SubscriptionImportance.low:
        return 'Low - Optional/Nice-to-have';
      case SubscriptionImportance.medium:
        return 'Medium - Regular use';
      case SubscriptionImportance.high:
        return 'High - Important service';
      case SubscriptionImportance.critical:
        return 'Critical - Essential service';
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

  String _getBillingCycleLabel(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
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

      final subscription = Subscription(
        id: widget.existingSubscription?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: 'USD',
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
            SnackBar(content: Text('Error saving subscription: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingSubscription != null;
    final currencyFormat = NumberFormat.currency(symbol: '');

    return Scaffold(
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
          child: Text(isEditing ? 'Edit Subscription' : 'Add Subscription'),
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
              child: const Text('Save'),
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
                    decoration: InputDecoration(
                      labelText: 'Subscription Name',
                      hintText: 'e.g., Netflix, Spotify',
                      filled: true,
                      fillColor: colorScheme.surface.withValues(alpha: 0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subscription name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category and Amount row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            filled: true,
                            fillColor:
                                colorScheme.surface.withValues(alpha: 0.95),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _defaultCategories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '\$ ',
                            filled: true,
                            fillColor:
                                colorScheme.surface.withValues(alpha: 0.95),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Billing cycle and importance
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BillingCycle>(
                          initialValue: _billingCycle,
                          decoration: InputDecoration(
                            labelText: 'Billing Cycle',
                            filled: true,
                            fillColor:
                                colorScheme.surface.withValues(alpha: 0.95),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: BillingCycle.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_getBillingCycleLabel(c)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _billingCycle = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<SubscriptionImportance>(
                          initialValue: _importance,
                          decoration: InputDecoration(
                            labelText: 'Importance',
                            filled: true,
                            fillColor:
                                colorScheme.surface.withValues(alpha: 0.95),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: SubscriptionImportance.values
                              .map((imp) => DropdownMenuItem(
                                    value: imp,
                                    child: Row(
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
                                        Text(imp.name.toUpperCase()),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _importance = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cost summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppSurfaces.elevated(
                      context,
                      radius: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cost Summary',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Cost',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
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
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Annual Cost',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
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
                                ),
                              ],
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
                    decoration: BoxDecoration(
                      color: _getImportanceColor(_importance)
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: _getImportanceColor(_importance)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                            _getImportanceLabel(_importance),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                          icon: const Icon(Icons.calendar_today),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
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
                          icon: const Icon(Icons.calendar_today),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Billing',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(_nextBillingDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Optional fields section
                  Text(
                    'Optional Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Payment method
                  TextFormField(
                    controller: _paymentMethodController,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      hintText: 'e.g., Credit Card, PayPal',
                      filled: true,
                      fillColor: colorScheme.surface.withValues(alpha: 0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Website
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(
                      labelText: 'Website',
                      hintText: 'e.g., netflix.com',
                      filled: true,
                      fillColor: colorScheme.surface.withValues(alpha: 0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add any notes about this subscription',
                      filled: true,
                      fillColor: colorScheme.surface.withValues(alpha: 0.95),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Decision helper section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'Decision Help',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
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
    final annualCost = _annualCost;
    String suggestion = '';
    IconData icon = Icons.info;
    Color color = colorScheme.outline;

    if (annualCost == 0) {
      suggestion = 'Enter an amount to see suggestions';
    } else if (annualCost > 500) {
      suggestion = 'High annual cost (\$$annualCost.toStringAsFixed(0)) - '
          'Consider if this is essential or could be replaced';
      color = Colors.red;
      icon = Icons.warning;
    } else if (annualCost > 200) {
      suggestion = 'Moderate annual cost (\$$annualCost.toStringAsFixed(0)) - '
          'Make sure you actively use this';
      color = Colors.orange;
      icon = Icons.info_outline;
    } else {
      suggestion = 'Track regularly to avoid inactive subscriptions';
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
