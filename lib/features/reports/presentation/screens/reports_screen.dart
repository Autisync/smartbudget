import 'dart:ui';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:csv/csv.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          child: const Text('Reports & Export'),
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
                      key: const ValueKey('reports-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('reports-appbar-blur-off')),
            ),
          ],
        ),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _isAppBarScrolled ? 0.9 : 0,
              ),
            ),
            icon: const Icon(Icons.share),
            onPressed: _isGenerating ? null : _showExportOptions,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              Container(
                decoration: AppSurfaces.elevated(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Period',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('From'),
                                TextButton(
                                  onPressed: () => _selectDate(context, true),
                                  child: Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_startDate),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('To'),
                                TextButton(
                                  onPressed: () => _selectDate(context, false),
                                  child: Text(
                                    DateFormat('MMM dd, yyyy').format(_endDate),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Period Buttons
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildPeriodButton('This Week', _setThisWeek),
                  _buildPeriodButton('This Month', _setThisMonth),
                  _buildPeriodButton('Last Month', _setLastMonth),
                  _buildPeriodButton('Last 3 Months', _setLast3Months),
                  _buildPeriodButton('This Year', _setThisYear),
                ],
              ),

              const SizedBox(height: 32),

              // Report Actions
              const Text(
                'Generate Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Financial Summary',
                'Complete overview of income, expenses, and savings',
                Icons.summarize,
                _generateFinancialSummary,
              ),
              _buildReportCard(
                'Transaction History',
                'Detailed list of all transactions in the period',
                Icons.receipt_long,
                _generateTransactionHistory,
              ),
              _buildReportCard(
                'Budget Analysis',
                'Budget performance and spending patterns',
                Icons.account_balance_wallet,
                _generateBudgetAnalysis,
              ),
              _buildReportCard(
                'Subscription Costs',
                'Monthly breakdown of subscription expenses',
                Icons.subscriptions,
                _generateSubscriptionReport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildReportCard(
      String title, String description, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppSurfaces.elevated(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
        trailing: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: _isGenerating ? null : onPressed,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _startDate =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      _endDate = DateTime.now();
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime.now();
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    setState(() {
      _startDate = lastMonth;
      _endDate = lastDayOfLastMonth;
    });
  }

  void _setLast3Months() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 3, 1);
      _endDate = DateTime.now();
    });
  }

  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime.now();
    });
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export as PDF'),
            onTap: () {
              Navigator.pop(context);
              _generateFinancialSummary();
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export as CSV'),
            onTap: () {
              Navigator.pop(context);
              _exportAsCSV();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateFinancialSummary() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();

      // Get data
      final transactions = await ref.read(transactionListProvider().future);
      final subscriptions = await ref.read(subscriptionListProvider.future);
      final budgets = await ref.read(budgetListProvider.future);

      final filteredTransactions = transactions
          .where((t) =>
              t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate.add(const Duration(days: 1))))
          .toList();

      final income = filteredTransactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final expenses = filteredTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final netIncome = income - expenses;

      // Calculate subscription costs for the period
      final subscriptionCosts =
          subscriptions.fold<double>(0, (sum, s) => sum + s.monthlyCost);

      // Calculate budget utilization
      final budgetUtilization = <String, double>{};
      for (final budget in budgets) {
        final spent = await ref.read(budgetSpendingProvider(
          category: budget.category,
          start: _startDate,
          end: _endDate,
        ).future);
        budgetUtilization[budget.category] = spent / budget.limitAmount;
      }

      // Generate PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Financial Summary Report'),
                ),
                pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('Income & Expenses:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Total Income: \$${income.toStringAsFixed(2)}'),
                pw.Text('Total Expenses: \$${expenses.toStringAsFixed(2)}'),
                pw.Text('Net Income: \$${netIncome.toStringAsFixed(2)}'),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Monthly Subscriptions: \$${subscriptionCosts.toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                pw.Text('Budget Utilization:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...budgetUtilization.entries.map((entry) => pw.Text(
                    '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%')),
                pw.SizedBox(height: 20),
                pw.Text('Recent Transactions:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...filteredTransactions.take(10).map((t) => pw.Text(
                    '${DateFormat('MM/dd').format(t.date)} ${t.category}: \$${t.amount.toStringAsFixed(2)} ${t.type == TransactionType.income ? '(Income)' : '(Expense)'}')),
              ],
            );
          },
        ),
      );

      // Save and share
      final output = await _getOutputFile('financial_summary.pdf');
      await output.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path)],
          text: 'Financial Summary Report',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report generated and shared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateTransactionHistory() async {
    setState(() => _isGenerating = true);

    try {
      final transactions = await ref.read(transactionListProvider().future);
      final filteredTransactions = transactions
          .where((t) =>
              t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate.add(const Duration(days: 1))))
          .toList();

      final csvData = [
        ['Date', 'Category', 'Amount', 'Type', 'Note'],
        ...filteredTransactions.map((t) => [
              DateFormat('yyyy-MM-dd').format(t.date),
              t.category,
              t.amount.toString(),
              t.type.name,
              t.note ?? '',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final output = await _getOutputFile('transaction_history.csv');
      await output.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path)],
          text: 'Transaction History Export',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction history exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateBudgetAnalysis() async {
    setState(() => _isGenerating = true);

    try {
      final budgets = await ref.read(budgetListProvider.future);
      final pdf = pw.Document();

      // Calculate spending for each budget
      final budgetData = <Map<String, dynamic>>[];
      for (final budget in budgets) {
        final spent = await ref.read(budgetSpendingProvider(
          category: budget.category,
          start: _startDate,
          end: _endDate,
        ).future);
        final percentage = (spent / budget.limitAmount) * 100;
        final status = percentage > 100
            ? 'Over Budget'
            : percentage > 80
                ? 'Near Limit'
                : 'On Track';

        budgetData.add({
          'category': budget.category,
          'limit': budget.limitAmount,
          'spent': spent,
          'percentage': percentage,
          'status': status,
        });
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('Budget Analysis Report')),
                pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('Budget Performance:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...budgetData.map((data) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${data['category']}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Limit: \$${data['limit'].toStringAsFixed(2)}'),
                        pw.Text(
                            'Spent: \$${data['spent'].toStringAsFixed(2)} (${data['percentage'].toStringAsFixed(1)}%)'),
                        pw.Text('Status: ${data['status']}',
                            style: pw.TextStyle(
                              color: data['status'] == 'Over Budget'
                                  ? PdfColors.red
                                  : data['status'] == 'Near Limit'
                                      ? PdfColors.orange
                                      : PdfColors.green,
                            )),
                        pw.SizedBox(height: 10),
                      ],
                    )),
                pw.SizedBox(height: 20),
                pw.Text('Summary:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Total Budgets: ${budgets.length}'),
                pw.Text(
                    'Over Budget: ${budgetData.where((b) => b['percentage'] > 100).length}'),
                pw.Text(
                    'Near Limit: ${budgetData.where((b) => b['percentage'] > 80 && b['percentage'] <= 100).length}'),
                pw.Text(
                    'On Track: ${budgetData.where((b) => b['percentage'] <= 80).length}'),
              ],
            );
          },
        ),
      );

      final output = await _getOutputFile('budget_analysis.pdf');
      await output.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path)],
          text: 'Budget Analysis Report',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget analysis report generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateSubscriptionReport() async {
    setState(() => _isGenerating = true);

    try {
      final subscriptions = await ref.read(subscriptionListProvider.future);
      final activeSubscriptions =
          subscriptions.where((s) => s.isActive).toList();
      final monthlyTotal =
          activeSubscriptions.fold<double>(0, (sum, s) => sum + s.monthlyCost);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('Subscription Report')),
                pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('Summary:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Total Active Subscriptions: ${activeSubscriptions.length}'),
                pw.Text(
                    'Monthly Total Cost: \$${monthlyTotal.toStringAsFixed(2)}'),
                pw.Text(
                    'Yearly Total Cost: \$${(monthlyTotal * 12).toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                pw.Text('Active Subscriptions:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...activeSubscriptions.map((s) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(s.name,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            'Amount: \$${s.amount.toStringAsFixed(2)} (${s.billingCycle.name})'),
                        pw.Text(
                            'Monthly Cost: \$${s.monthlyCost.toStringAsFixed(2)}'),
                        pw.Text('Category: ${s.category}'),
                        pw.Text(
                            'Next Due: ${DateFormat('MMM dd, yyyy').format(s.nextDueDate)}'),
                        pw.SizedBox(height: 10),
                      ],
                    )),
              ],
            );
          },
        ),
      );

      final output = await _getOutputFile('subscription_report.pdf');
      await output.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path)],
          text: 'Subscription Report',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription report generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportAsCSV() async {
    setState(() => _isGenerating = true);

    try {
      final transactions = await ref.read(transactionListProvider().future);
      final subscriptions = await ref.read(subscriptionListProvider.future);

      final csvData = [
        ['Type', 'Date', 'Category', 'Amount', 'Description'],
        ...transactions.map((t) => [
              'Transaction',
              DateFormat('yyyy-MM-dd').format(t.date),
              t.category,
              t.amount.toString(),
              t.note ?? '',
            ]),
        ...subscriptions.map((s) => [
              'Subscription',
              DateFormat('yyyy-MM-dd').format(s.startDate),
              s.category,
              s.amount.toString(),
              s.name,
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final output = await _getOutputFile('complete_export.csv');
      await output.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(output.path)],
          text: 'Complete Data Export',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete data export created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<File> _getOutputFile(String filename) async {
    final directory = Directory('/tmp'); // Use temp directory for sharing
    return File('${directory.path}/$filename');
  }
}
