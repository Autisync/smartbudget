import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/core/widgets/form_date_field.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appCurrency = ref.watch(appCurrencyControllerProvider);
    final appCurrencyLabel = appCurrency.toUpperCase();
    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.reportsTitle,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0.0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'reports-appbar-blur-on',
          offKey: 'reports-appbar-blur-off',
        ),
        actions: [
          ...buildPageHeaderActions(
            context: context,
            isScrolled: _isAppBarScrolled,
            includeTrailingSpace: false,
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _isAppBarScrolled ? 0.9 : 0.0,
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
          padding: UiTokens.adaptiveScrollablePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartSpendHeader(
                title: 'Reports & Export',
                subtitle:
                    'Generate polished financial reports with flexible date ranges and quick exports.',
                trailing: AppBadge(
                  label: appCurrencyLabel,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Date Range Selector
              SmartCard(
                radius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reportsPeriod,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: l10n.reportsFrom,
                            date: _startDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: l10n.reportsTo,
                            date: _endDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: UiTokens.sectionGapLg),

              // Quick Period Buttons
              Text(
                l10n.reportsQuickSelect,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: UiTokens.chipSpacing),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPeriodButton(l10n.reportsThisWeek, _setThisWeek),
                  _buildPeriodButton(l10n.reportsThisMonth, _setThisMonth),
                  _buildPeriodButton(l10n.reportsLastMonth, _setLastMonth),
                  _buildPeriodButton(l10n.reportsLast3Months, _setLast3Months),
                  _buildPeriodButton(l10n.reportsThisYear, _setThisYear),
                ],
              ),

              const SizedBox(height: 32),
              _buildReportMetricsSection(),

              const SizedBox(height: UiTokens.sectionGapLg),

              // Report Actions
              Text(
                l10n.reportsGenerateReports,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: UiTokens.sectionGapMd),
              _buildReportCard(
                reportKey: 'Financial Summary',
                title: l10n.reportsFinancialSummary(appCurrencyLabel),
                description: l10n.reportsFinancialSummaryDescription,
                icon: Icons.analytics_rounded,
                onPressed: _generateFinancialSummary,
              ),
              _buildReportCard(
                reportKey: 'Transaction History',
                title: l10n.reportsTransactionHistory,
                description: l10n.reportsTransactionHistoryDescription,
                icon: Icons.receipt_long_rounded,
                onPressed: _generateTransactionHistory,
              ),
              _buildReportCard(
                reportKey: 'Budget Analysis',
                title: l10n.reportsBudgetAnalysis,
                description: l10n.reportsBudgetAnalysisDescription,
                icon: Icons.pie_chart_rounded,
                onPressed: _generateBudgetAnalysis,
              ),
              _buildReportCard(
                reportKey: 'Subscription Costs',
                title: l10n.reportsSubscriptionCosts,
                description: l10n.reportsSubscriptionCostsDescription,
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.reportsActivity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              AppDonutChart(
                segments: [
                  AppDonutSegment(
                    value: _totalReportsGenerated
                        .toDouble()
                        .clamp(1, 9999)
                        .toDouble(),
                    color: colorScheme.primary,
                  ),
                  AppDonutSegment(
                    value: generatedToday.toDouble().clamp(1, 9999).toDouble(),
                    color: colorScheme.tertiary,
                  ),
                  AppDonutSegment(
                    value: _reportCounts.length
                        .toDouble()
                        .clamp(1, 9999)
                        .toDouble(),
                    color: colorScheme.secondary,
                  ),
                ],
                radius: 22,
                centerSpaceRadius: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: UiTokens.chipSpacing,
            runSpacing: UiTokens.chipRunSpacing,
            children: [
              _ReportMetricChip(
                label: l10n.reportsGenerated,
                value: '$_totalReportsGenerated',
                icon: Icons.description_rounded,
              ),
              _ReportMetricChip(
                label: l10n.reportsToday,
                value: '$generatedToday',
                icon: Icons.today_rounded,
              ),
              _ReportMetricChip(
                label: l10n.reportsTypesUsed,
                value: '${_reportCounts.length}',
                icon: Icons.category_rounded,
              ),
              _ReportMetricChip(
                label: l10n.reportsLastRun,
                value: _lastGeneratedAt == null
                    ? l10n.reportsNone
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
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    return FormDateField(
      label: label,
      value: DateFormat('MMM dd, yyyy').format(date),
      onTap: onTap,
    );
  }

  Widget _buildReportCard(
      {required String reportKey,
      required String title,
      required String description,
      required IconData icon,
      required VoidCallback onPressed}) {
    final runCount = _reportCounts[reportKey] ?? 0;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBadgeColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.85)
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SmartCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        onTap: _isGenerating ? null : onPressed,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBadgeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 25,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isGenerating
                ? const AppLottieView(
                    assetPath: 'assets/animations/report_generation.json',
                    width: 36,
                    height: 36,
                    repeat: true,
                    animate: true,
                    semanticLabel: 'Generating report',
                    fallbackIcon: Icons.sync,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.chevron_right_rounded, size: 18),
                      const SizedBox(height: 6),
                      Text(
                        l10n.reportsRuns(runCount),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedReportsSection() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.reportsGeneratedReports,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_generatedReports.isEmpty)
            const SmartEmptyState(
              icon: Icons.description_outlined,
              title: 'No Reports Generated',
              message:
                  'Run a report to see your latest exports and generated files here.',
              lottieAsset: 'assets/animations/empty_reports.json',
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
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
    final l10n = AppLocalizations.of(context)!;
    AppFormSheet.show(
      context,
      builder: (sheetContext) => AppFormSheet(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n.reportsExportAsPdf),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _generateFinancialSummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(l10n.reportsExportAsCsv),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _exportAsCSV();
              },
            ),
          ],
        ),
        maxHeightFactor: 0.42,
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

  String _getTransactionTypeLabel(TransactionType type, AppLocalizations l10n) {
    switch (type) {
      case TransactionType.income:
        return l10n.reportsTypeIncome;
      case TransactionType.expense:
        return l10n.reportsTypeExpense;
      case TransactionType.transfer:
        return l10n.reportsTypeTransfer;
    }
  }

  String _getBillingCycleLabel(BillingCycle cycle, AppLocalizations l10n) {
    switch (cycle) {
      case BillingCycle.weekly:
        return l10n.reportsBillingWeekly;
      case BillingCycle.monthly:
        return l10n.reportsBillingMonthly;
      case BillingCycle.quarterly:
        return l10n.reportsBillingQuarterly;
      case BillingCycle.yearly:
        return l10n.reportsBillingYearly;
    }
  }

  void _beginReportGeneration(String message) {
    setState(() => _isGenerating = true);
    AppFeedbackService.showLoading(context, message);
  }

  void _finishReportGeneration() {
    if (mounted) {
      setState(() => _isGenerating = false);
    }
    AppFeedbackService.dismissLoading();
  }

  Future<void> _generateFinancialSummary() async {
    _beginReportGeneration('Generating financial summary...');
    final l10n = AppLocalizations.of(context)!;

    try {
      final pdfTheme = await _buildPdfTheme();
      final pdf = pw.Document();
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final appCurrencySymbol = CurrencyUtils.symbol(appCurrency);

      // Get data
      final transactions = await ref.read(transactionListProvider().future);
      final subscriptions = await ref.read(subscriptionListProvider.future);
      final budgets = await ref.read(activeBudgetsProvider.future);

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
                  child: pw.Text(l10n.reportsPdfFinancialSummaryTitle),
                ),
                pw.Text(
                    '${l10n.reportsPdfPeriod}: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfIncomeExpenses}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${l10n.reportsPdfTotalIncome}: $appCurrencySymbol${income.toStringAsFixed(2)}'),
                pw.Text(
                    '${l10n.reportsPdfTotalExpenses}: $appCurrencySymbol${expenses.toStringAsFixed(2)}'),
                pw.Text(
                    '${l10n.reportsPdfNetIncome}: $appCurrencySymbol${netIncome.toStringAsFixed(2)}'),
                pw.SizedBox(height: 10),
                pw.Text(
                    '${l10n.reportsPdfMonthlySubscriptions}: $appCurrencySymbol${subscriptionCosts.toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfBudgetUtilization}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...budgetUtilization.entries.map((entry) => pw.Text(
                    '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%')),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfRecentTransactions}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...filteredTransactions.take(10).map((t) => pw.Text(
                    '${DateFormat('MM/dd').format(t.date)} ${t.category}: $appCurrencySymbol${t.amount.toStringAsFixed(2)} (${_getTransactionTypeLabel(t.type, l10n)})')),
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
        title: l10n.reportsFinancialSummary(appCurrency.toUpperCase()),
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.analytics_rounded,
      );

      await Share.shareXFiles(
        [XFile(output.path)],
        text: l10n.reportsShareFinancialSummary,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(context, l10n.reportsPdfGeneratedShared);
      }
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(e.toString()),
        );
      }
    } finally {
      _finishReportGeneration();
    }
  }

  Future<void> _generateTransactionHistory() async {
    _beginReportGeneration('Exporting transaction history...');
    final l10n = AppLocalizations.of(context)!;

    try {
      final transactions = await ref.read(transactionListProvider().future);
      final filteredTransactions = transactions
          .where((t) =>
              t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate.add(const Duration(days: 1))))
          .toList();

      final csvData = [
        [
          l10n.reportsCsvHeaderDate,
          l10n.reportsCsvHeaderCategory,
          l10n.reportsCsvHeaderAmount,
          l10n.reportsCsvHeaderType,
          l10n.reportsCsvHeaderNote,
        ],
        ...filteredTransactions.map((t) => [
              DateFormat('yyyy-MM-dd').format(t.date),
              t.category,
              t.amount.toString(),
              _getTransactionTypeLabel(t.type, l10n),
              t.note ?? '',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final output = await _getOutputFile('transaction_history.csv');
      await output.writeAsString(csvString);

      _trackGeneratedReport(
        reportKey: 'Transaction History',
        title: l10n.reportsTransactionHistory,
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.receipt_long_rounded,
      );

      await Share.shareXFiles(
        [XFile(output.path)],
        text: l10n.reportsShareTransactionHistory,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsTransactionHistoryExported,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorExportingData(e.toString()),
        );
      }
    } finally {
      _finishReportGeneration();
    }
  }

  Future<void> _generateBudgetAnalysis() async {
    _beginReportGeneration('Generating budget analysis...');
    final l10n = AppLocalizations.of(context)!;

    try {
      final budgets = await ref.read(activeBudgetsProvider.future);
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
            ? l10n.reportsStatusOverBudget
            : percentage > 80
                ? l10n.reportsStatusNearLimit
                : l10n.reportsStatusOnTrack;

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
                pw.Header(
                    level: 0,
                    child: pw.Text(l10n.reportsPdfBudgetAnalysisTitle)),
                pw.Text(
                    '${l10n.reportsPdfPeriod}: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfBudgetPerformance}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...budgetData.map((data) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${data['category']}',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            '${l10n.reportsPdfLimit}: $appCurrencySymbol${data['limit'].toStringAsFixed(2)}'),
                        pw.Text(
                            '${l10n.reportsPdfSpent}: $appCurrencySymbol${data['spent'].toStringAsFixed(2)} (${data['percentage'].toStringAsFixed(1)}%)'),
                        pw.Text('${l10n.reportsPdfStatus}: ${data['status']}',
                            style: pw.TextStyle(
                              color:
                                  data['status'] == l10n.reportsStatusOverBudget
                                      ? PdfColors.red
                                      : data['status'] ==
                                              l10n.reportsStatusNearLimit
                                          ? PdfColors.orange
                                          : PdfColors.green,
                            )),
                        pw.SizedBox(height: 10),
                      ],
                    )),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfSummary}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${l10n.reportsPdfTotalBudgets}: ${budgets.length}'),
                pw.Text(
                    '${l10n.reportsPdfOverBudget}: ${budgetData.where((b) => b['percentage'] > 100).length}'),
                pw.Text(
                    '${l10n.reportsPdfNearLimit}: ${budgetData.where((b) => b['percentage'] > 80 && b['percentage'] <= 100).length}'),
                pw.Text(
                    '${l10n.reportsPdfOnTrack}: ${budgetData.where((b) => b['percentage'] <= 80).length}'),
              ],
            );
          },
        ),
      );

      final output = await _getOutputFile('budget_analysis.pdf');
      await output.writeAsBytes(await pdf.save());

      _trackGeneratedReport(
        reportKey: 'Budget Analysis',
        title: l10n.reportsBudgetAnalysis,
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.pie_chart_rounded,
      );

      await Share.shareXFiles(
        [XFile(output.path)],
        text: l10n.reportsShareBudgetAnalysis,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsBudgetAnalysisGenerated,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(e.toString()),
        );
      }
    } finally {
      _finishReportGeneration();
    }
  }

  Future<void> _generateSubscriptionReport() async {
    _beginReportGeneration('Generating subscription report...');
    final l10n = AppLocalizations.of(context)!;

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
                pw.Header(
                    level: 0,
                    child: pw.Text(l10n.reportsPdfSubscriptionReportTitle)),
                pw.Text(
                    '${l10n.reportsPdfPeriod}: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfSummary}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${l10n.reportsPdfTotalActiveSubscriptions}: ${activeSubscriptions.length}'),
                pw.Text(
                    '${l10n.reportsPdfMonthlyTotalCost}: $appCurrencySymbol${monthlyTotal.toStringAsFixed(2)}'),
                pw.Text(
                    '${l10n.reportsPdfYearlyTotalCost}: $appCurrencySymbol${(monthlyTotal * 12).toStringAsFixed(2)}'),
                pw.SizedBox(height: 20),
                pw.Text('${l10n.reportsPdfActiveSubscriptions}:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...activeSubscriptions.map((s) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(s.name,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            '${l10n.reportsPdfAmount}: $appCurrencySymbol${s.amount.toStringAsFixed(2)} (${_getBillingCycleLabel(s.billingCycle, l10n)})'),
                        pw.Text(
                            '${l10n.reportsPdfMonthlyCost}: $appCurrencySymbol${s.monthlyCost.toStringAsFixed(2)}'),
                        pw.Text('${l10n.category}: ${s.category}'),
                        pw.Text(
                            '${l10n.reportsPdfNextDue}: ${DateFormat('MMM dd, yyyy').format(s.nextDueDate)}'),
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
        title: l10n.reportsSubscriptionCosts,
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.subscriptions_rounded,
      );

      await Share.shareXFiles(
        [XFile(output.path)],
        text: l10n.reportsShareSubscriptionReport,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsSubscriptionReportGenerated,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(e.toString()),
        );
      }
    } finally {
      _finishReportGeneration();
    }
  }

  Future<void> _exportAsCSV() async {
    _beginReportGeneration('Exporting complete data...');
    final l10n = AppLocalizations.of(context)!;

    try {
      final transactions = await ref.read(transactionListProvider().future);
      final subscriptions = await ref.read(subscriptionListProvider.future);

      final csvData = [
        [
          l10n.reportsCsvHeaderType,
          l10n.reportsCsvHeaderDate,
          l10n.reportsCsvHeaderCategory,
          l10n.reportsCsvHeaderAmount,
          l10n.reportsCsvHeaderDescription,
        ],
        ...transactions.map((t) => [
              l10n.reportsCsvRowTransaction,
              DateFormat('yyyy-MM-dd').format(t.date),
              t.category,
              t.amount.toString(),
              t.note ?? '',
            ]),
        ...subscriptions.map((s) => [
              l10n.reportsCsvRowSubscription,
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
        title: l10n.reportsCompleteDataExportTitle,
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.table_chart_rounded,
      );

      await Share.shareXFiles(
        [XFile(output.path)],
        text: l10n.reportsShareCompleteDataExport,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsCompleteDataExportCreated,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorExportingData(e.toString()),
        );
      }
    } finally {
      _finishReportGeneration();
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
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
