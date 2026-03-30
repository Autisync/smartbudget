import 'dart:ui';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
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
  pw.Font? _pdfFontRegular;
  pw.Font? _pdfFontBold;
  int _totalReportsGenerated = 0;
  DateTime? _lastGeneratedAt;
  final Map<String, int> _reportCounts = <String, int>{};
  final List<_GeneratedReportEntry> _generatedReports =
      <_GeneratedReportEntry>[];

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
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final appCurrencyLabel = appCurrency.toUpperCase();
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
            icon: const Icon(Icons.ios_share_rounded),
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
          padding: UiTokens.screenPaddingScrollable,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              Container(
                decoration: AppSurfaces.elevated(
                  context,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.7),
                ),
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
                            child: _buildDateField(
                              label: 'From',
                              date: _startDate,
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              label: 'To',
                              date: _endDate,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: UiTokens.sectionGapLg),

              // Quick Period Buttons
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: UiTokens.chipSpacing),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPeriodButton('This Week', _setThisWeek),
                  _buildPeriodButton('This Month', _setThisMonth),
                  _buildPeriodButton('Last Month', _setLastMonth),
                  _buildPeriodButton('Last 3 Months', _setLast3Months),
                  _buildPeriodButton('This Year', _setThisYear),
                ],
              ),

              const SizedBox(height: 32),

              _buildReportMetricsSection(),

              const SizedBox(height: UiTokens.sectionGapLg),

              // Report Actions
              const Text(
                'Generate Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: UiTokens.sectionGapMd),
              _buildReportCard(
                reportKey: 'Financial Summary',
                title: 'Financial Summary ($appCurrencyLabel)',
                description:
                    'Complete overview of income, expenses, and savings',
                icon: Icons.analytics_rounded,
                onPressed: _generateFinancialSummary,
              ),
              _buildReportCard(
                reportKey: 'Transaction History',
                title: 'Transaction History',
                description: 'Detailed list of all transactions in the period',
                icon: Icons.receipt_long_rounded,
                onPressed: _generateTransactionHistory,
              ),
              _buildReportCard(
                reportKey: 'Budget Analysis',
                title: 'Budget Analysis',
                description: 'Budget performance and spending patterns',
                icon: Icons.pie_chart_rounded,
                onPressed: _generateBudgetAnalysis,
              ),
              _buildReportCard(
                reportKey: 'Subscription Costs',
                title: 'Subscription Costs',
                description: 'Monthly breakdown of subscription expenses',
                icon: Icons.subscriptions_rounded,
                onPressed: _generateSubscriptionReport,
              ),

              const SizedBox(height: UiTokens.sectionGapLg),
              _buildGeneratedReportsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportMetricsSection() {
    final generatedToday = _generatedReports.where((entry) {
      final now = DateTime.now();
      return entry.generatedAt.year == now.year &&
          entry.generatedAt.month == now.month &&
          entry.generatedAt.day == now.day;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppSurfaces.elevated(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Report Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: UiTokens.chipSpacing,
            runSpacing: UiTokens.chipRunSpacing,
            children: [
              _ReportMetricChip(
                label: 'Generated',
                value: '$_totalReportsGenerated',
                icon: Icons.description_rounded,
              ),
              _ReportMetricChip(
                label: 'Today',
                value: '$generatedToday',
                icon: Icons.today_rounded,
              ),
              _ReportMetricChip(
                label: 'Types Used',
                value: '${_reportCounts.length}',
                icon: Icons.category_rounded,
              ),
              _ReportMetricChip(
                label: 'Last Run',
                value: _lastGeneratedAt == null
                    ? 'None'
                    : DateFormat('MMM dd, HH:mm').format(_lastGeneratedAt!),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      {required String reportKey,
      required String title,
      required String description,
      required IconData icon,
      required VoidCallback onPressed}) {
    final runCount = _reportCounts[reportKey] ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBadgeColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.85)
        : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppSurfaces.elevated(context),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconBadgeColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            size: 25,
            color: Colors.white,
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  const SizedBox(height: 6),
                  Text(
                    '$runCount runs',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
        onTap: _isGenerating ? null : onPressed,
      ),
    );
  }

  Widget _buildGeneratedReportsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppSurfaces.elevated(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Generated Reports',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_generatedReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No reports generated yet. Run any report to see it listed here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ..._generatedReports.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Icon(
                      entry.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    subtitle: Text(
                      '${entry.format} • ${DateFormat('MMM dd, yyyy HH:mm').format(entry.generatedAt)} • ${entry.filename}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _trackGeneratedReport({
    required String reportKey,
    required String title,
    required String format,
    required String filename,
    required IconData icon,
  }) {
    final now = DateTime.now();
    setState(() {
      _totalReportsGenerated += 1;
      _lastGeneratedAt = now;
      _reportCounts.update(reportKey, (value) => value + 1, ifAbsent: () => 1);
      _generatedReports.insert(
        0,
        _GeneratedReportEntry(
          title: title,
          format: format,
          filename: filename,
          generatedAt: now,
          icon: icon,
        ),
      );
      if (_generatedReports.length > 10) {
        _generatedReports.removeLast();
      }
    });
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

  Future<pw.ThemeData> _buildPdfTheme() async {
    _pdfFontRegular ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    _pdfFontBold ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    return pw.ThemeData.withFont(
      base: _pdfFontRegular!,
      bold: _pdfFontBold!,
    );
  }

  String _getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
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

  Future<void> _generateFinancialSummary() async {
    setState(() => _isGenerating = true);

    try {
      final pdfTheme = await _buildPdfTheme();
      final pdf = pw.Document();
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final appCurrencySymbol = CurrencyUtils.symbol(appCurrency);

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
          theme: pdfTheme,
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
                pw.Text(
                    'Total Income: $appCurrencySymbol${income.toStringAsFixed(2)}'),
                pw.Text(
                    'Total Expenses: $appCurrencySymbol${expenses.toStringAsFixed(2)}'),
                pw.Text(
                    'Net Income: $appCurrencySymbol${netIncome.toStringAsFixed(2)}'),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Monthly Subscriptions: $appCurrencySymbol${subscriptionCosts.toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                pw.Text('Budget Utilization:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...budgetUtilization.entries.map((entry) => pw.Text(
                    '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%')),
                pw.SizedBox(height: 20),
                pw.Text('Recent Transactions:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...filteredTransactions.take(10).map((t) => pw.Text(
                    '${DateFormat('MM/dd').format(t.date)} ${t.category}: $appCurrencySymbol${t.amount.toStringAsFixed(2)} ${t.type == TransactionType.income ? '(Income)' : '(Expense)'}')),
              ],
            );
          },
        ),
      );

      // Save and share
      final output = await _getOutputFile('financial_summary.pdf');
      await output.writeAsBytes(await pdf.save());

      _trackGeneratedReport(
        reportKey: 'Financial Summary',
        title: 'Financial Summary',
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.analytics_rounded,
      );

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
              _getTransactionTypeLabel(t.type),
              t.note ?? '',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final output = await _getOutputFile('transaction_history.csv');
      await output.writeAsString(csvString);

      _trackGeneratedReport(
        reportKey: 'Transaction History',
        title: 'Transaction History',
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.receipt_long_rounded,
      );

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
      final pdfTheme = await _buildPdfTheme();
      final pdf = pw.Document();
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final appCurrencySymbol = CurrencyUtils.symbol(appCurrency);

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
          theme: pdfTheme,
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
                        pw.Text(
                            'Limit: $appCurrencySymbol${data['limit'].toStringAsFixed(2)}'),
                        pw.Text(
                            'Spent: $appCurrencySymbol${data['spent'].toStringAsFixed(2)} (${data['percentage'].toStringAsFixed(1)}%)'),
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

      _trackGeneratedReport(
        reportKey: 'Budget Analysis',
        title: 'Budget Analysis',
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.pie_chart_rounded,
      );

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
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final appCurrencySymbol = CurrencyUtils.symbol(appCurrency);

      final pdf = pw.Document();
      final pdfTheme = await _buildPdfTheme();

      pdf.addPage(
        pw.Page(
          theme: pdfTheme,
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
                    'Monthly Total Cost: $appCurrencySymbol${monthlyTotal.toStringAsFixed(2)}'),
                pw.Text(
                    'Yearly Total Cost: $appCurrencySymbol${(monthlyTotal * 12).toStringAsFixed(2)}'),
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
                            'Amount: $appCurrencySymbol${s.amount.toStringAsFixed(2)} (${_getBillingCycleLabel(s.billingCycle)})'),
                        pw.Text(
                            'Monthly Cost: $appCurrencySymbol${s.monthlyCost.toStringAsFixed(2)}'),
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

      _trackGeneratedReport(
        reportKey: 'Subscription Costs',
        title: 'Subscription Report',
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.subscriptions_rounded,
      );

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

      _trackGeneratedReport(
        reportKey: 'Complete Export',
        title: 'Complete Data Export',
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.table_chart_rounded,
      );

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
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }
}

class _ReportMetricChip extends StatelessWidget {
  const _ReportMetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratedReportEntry {
  const _GeneratedReportEntry({
    required this.title,
    required this.format,
    required this.filename,
    required this.generatedAt,
    required this.icon,
  });

  final String title;
  final String format;
  final String filename;
  final DateTime generatedAt;
  final IconData icon;
}
