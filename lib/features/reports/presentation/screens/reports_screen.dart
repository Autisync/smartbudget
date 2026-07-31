import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;
import 'package:smartbudget/components/app_ui.dart';
import 'package:smartbudget/components/financial/insight_portfolio_card.dart';
import 'package:smartbudget/components/forms/app_action_menu.dart';
import 'package:smartbudget/components/forms/modern_date_picker.dart';
import 'package:smartbudget/core/errors/app_error_mapper.dart';
import 'package:smartbudget/core/monitoring/error_monitor.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/theme/ui_tokens.dart';
import 'package:smartbudget/core/widgets/fintech_components.dart' show AppBadge;
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/data/models/tables.dart';
import 'package:smartbudget/features/budgets/presentation/providers/budget_provider.dart';
import 'package:smartbudget/features/subscriptions/presentation/providers/subscription_provider.dart';
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smartbudget/intelligence/utils/currency_utils.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class ReportGenerationOptions {
  const ReportGenerationOptions({
    required this.includeCharts,
    required this.includeDetailedTransactions,
    required this.includeBudgets,
    required this.includeSubscriptions,
    required this.includeSavingsGoals,
  });

  final bool includeCharts;
  final bool includeDetailedTransactions;
  final bool includeBudgets;
  final bool includeSubscriptions;
  final bool includeSavingsGoals;
}

typedef ReportsGenerationExecutor = Future<void> Function(
  String reportKey,
  String format,
  ReportGenerationOptions options,
);

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({
    super.key,
    this.generationExecutor,
  });

  final ReportsGenerationExecutor? generationExecutor;

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

  _QuickRangeFilter _quickRangeFilter = _QuickRangeFilter.thisMonth;
  _ReportActivityFilter _activityFilter = _ReportActivityFilter.all;

  DateTime? _lastGeneratedAt;
  final Map<String, int> _reportCounts = <String, int>{};
  final List<_GeneratedReportEntry> _generatedReports =
      <_GeneratedReportEntry>[];
  final List<_ReportActivityEntry> _activities = <_ReportActivityEntry>[];

  late List<_AvailableReportTemplate> _availableReports =
      const <_AvailableReportTemplate>[];

  _ReportsSummary _summary = const _ReportsSummary.empty();

  @override
  void initState() {
    super.initState();
    _recomputeSummary();
  }

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
    final l10n = AppLocalizations.of(context)!;
    _availableReports = _buildAvailableReportTemplates(l10n);

    return AppScaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.reportsTitleExport,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withOpacity(
          _isAppBarScrolled ? 0.88 : 0.0,
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
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(
                _isAppBarScrolled ? 0.9 : 0.0,
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _isGenerating ? null : _openExportWorkflowSheet,
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
              AppHeader(
                title: l10n.reportsTitleExport,
                subtitle:
                    'Generate, export, and review your financial reports.',
              ),
              const SizedBox(height: 20),
              _buildOverviewInsightCard(context),
              const SizedBox(height: UiTokens.sectionGapLg),
              _buildDateRangeAndFilters(context),
              const SizedBox(height: UiTokens.sectionGapLg),
              _buildAvailableReportsSection(context),
              const SizedBox(height: UiTokens.sectionGapLg),
              _buildRecentActivitySection(context),
              const SizedBox(height: UiTokens.sectionGapLg),
              _buildGeneratedReportsSection(context),
              SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewInsightCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final insightText = _summary.generatedThisMonth > 0
        ? 'You have generated ${_summary.generatedThisMonth} reports this month. Export your latest summary for a clearer monthly view.'
        : 'No reports yet. Generate your first report to review spending, budgets, and savings progress.';

    return MinimalInsightCard(
      key: const ValueKey('reports-overview-card'),
      title: l10n.reportsOverviewTitle,
      icon: Icons.assessment_rounded,
      insightText: insightText,
      semanticTone: InsightCardSemanticTone.general,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEFF1FF),
          Color(0xFFEAF8FF),
        ],
      ),
      metrics: [
        MinimalInsightMetric(
          label: l10n.reportsGenerated,
          value: '${_summary.totalGenerated}',
        ),
        MinimalInsightMetric(
          label: l10n.transactionsFilterThisMonth,
          value: '${_summary.generatedThisMonth}',
        ),
        MinimalInsightMetric(
          label: l10n.reportsLastExport,
          value: _summary.lastExportAt == null
              ? 'None'
              : DateFormat('MMM dd').format(_summary.lastExportAt!),
        ),
        MinimalInsightMetric(
          label: l10n.reportsAvailableTypes,
          value: '${_availableReports.length}',
        ),
      ],
      footer: _isGenerating
          ? const AppLottieView(
              assetPath: 'assets/animations/report_generation.json',
              width: 44,
              height: 44,
              repeat: true,
              animate: true,
              semanticLabel: 'Generating report animation',
              fallbackIcon: Icons.sync_rounded,
            )
          : Text(
              'Updated ${DateFormat('MMM dd, HH:mm').format(now)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
    );
  }

  Widget _buildDateRangeAndFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      key: const ValueKey('reports-date-filter-card'),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range & Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _QuickRangeFilter.values
                .map((filter) => ChoiceChip(
                      key: ValueKey('reports-filter-${filter.key}'),
                      label: Text(filter.label),
                      selected: _quickRangeFilter == filter,
                      onSelected: (_) => _applyQuickFilter(filter),
                    ))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ModernDatePicker(
                  key: const ValueKey('reports-date-from'),
                  label: l10n.reportsFrom,
                  value: DateFormat('MMM dd, yyyy').format(_startDate),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernDatePicker(
                  key: const ValueKey('reports-date-to'),
                  label: l10n.reportsTo,
                  value: DateFormat('MMM dd, yyyy').format(_endDate),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableReportsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Reports',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          key: const ValueKey('available-reports-list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableReports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final template = _availableReports[index];
            final lastRun = _generatedReports
                .where((e) => e.reportKey == template.reportKey)
                .cast<_GeneratedReportEntry?>()
                .firstWhere((_) => true, orElse: () => null)
                ?.generatedAt;

            return AppCard(
              key: ValueKey('report-card-${template.reportKey}'),
              radius: 24,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 320;
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: l10n.commonGenerate,
                        icon: Icons.auto_graph_rounded,
                        onPressed: _isGenerating
                            ? null
                            : () => _openGenerationSheet(template),
                        expand: false,
                      ),
                      AppActionMenu(
                        title: '${template.title} actions',
                        tooltip: l10n.reportsActions,
                        onSelected: (value) {
                          if (value == 'schedule') {
                            _trackActivity(
                              title: '${template.title} scheduled',
                              status: _ReportActivityStatus.scheduled,
                              format: template.formats.first,
                              icon: Icons.schedule_rounded,
                            );
                            AppFeedbackService.showInfo(
                              context,
                              'Report scheduled.',
                            );
                          }
                        },
                        items: [
                          AppActionItem(
                            value: 'schedule',
                            label: l10n.reportsScheduleRun,
                            icon: Icons.schedule_rounded,
                          ),
                        ],
                      ),
                    ],
                  );

                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(template.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...template.formats.map(
                            (format) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                format,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              template.estimatedDurationLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (lastRun != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last generated ${DateFormat('MMM dd, yyyy HH:mm').format(lastRun)}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              template.icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: details),
                          if (!isCompact) ...[
                            const SizedBox(width: 8),
                            actions,
                          ],
                        ],
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 10),
                        actions,
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredActivities();

    return AppCard(
      key: const ValueKey('reports-activity-card'),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Report Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ReportActivityFilter.values
                .map(
                  (filter) => ChoiceChip(
                    key: ValueKey('reports-activity-filter-${filter.key}'),
                    label: Text(filter.label),
                    selected: _activityFilter == filter,
                    onSelected: (_) {
                      setState(() {
                        _activityFilter = filter;
                      });
                      AppFeedbackService.showInfo(context, 'Filter applied');
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            AppAnimatedEmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: l10n.reportsNoActivityTitle,
              message: l10n.reportsNoActivityMessage,
              lottieAsset: 'assets/animations/empty_reports.json',
              action: AppButton(
                label: l10n.reportsGenerateReport,
                icon: Icons.auto_graph_rounded,
                onPressed: _availableReports.isEmpty
                    ? null
                    : () => _openGenerationSheet(_availableReports.first),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppSurfaces.elevated(context, radius: 18),
                  child: Row(
                    children: [
                      Icon(entry.icon, color: entry.status.color(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, yyyy • HH:mm')
                                .format(entry.at)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppBadge(
                            label: entry.status.label,
                            color: entry.status.color(context),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              entry.format,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGeneratedReportsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      key: const ValueKey('generated-reports-card'),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Reports',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (_generatedReports.isEmpty)
            AppAnimatedEmptyState(
              icon: Icons.description_outlined,
              title: l10n.reportsNoGeneratedTitle,
              message:
                  'Generate your first report to build a reusable export history.',
              lottieAsset: 'assets/animations/empty_reports.json',
              action: AppButton(
                label: l10n.reportsGenerateReport,
                icon: Icons.add_chart_rounded,
                onPressed: _availableReports.isEmpty
                    ? null
                    : () => _openGenerationSheet(_availableReports.first),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedReports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = _generatedReports[index];
                return Container(
                  key: ValueKey('generated-report-${entry.reportKey}-$index'),
                  padding: const EdgeInsets.all(12),
                  decoration: AppSurfaces.elevated(context, radius: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(entry.icon,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.title} • ${entry.format} • ${DateFormat('MMM dd, yyyy HH:mm').format(entry.generatedAt)} • ${entry.fileSizeLabel}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.commonDownload,
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () {
                          _trackActivity(
                            title: '${entry.title} downloaded',
                            status: _ReportActivityStatus.downloaded,
                            format: entry.format,
                            icon: Icons.download_rounded,
                          );
                          AppFeedbackService.showInfo(
                              context, 'Download started');
                        },
                      ),
                      AppActionMenu(
                        title: '${entry.title} actions',
                        tooltip: l10n.reportsActivityActions,
                        onSelected: (value) {
                          if (value == 'share') {
                            _trackActivity(
                              title: '${entry.title} shared',
                              status: _ReportActivityStatus.exported,
                              format: entry.format,
                              icon: Icons.share_rounded,
                            );
                            AppFeedbackService.showSuccess(
                                context, 'Export completed');
                          }
                        },
                        items: [
                          AppActionItem(
                            value: 'share',
                            label: l10n.reportsShareExport,
                            icon: Icons.share_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openGenerationSheet(_AvailableReportTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    var selectedFormat = template.formats.first;
    var includeCharts = true;
    var includeDetailedTransactions = true;
    var includeBudgets = true;
    var includeSubscriptions = true;
    var includeSavingsGoals = true;

    await AppFormSheet.show(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AppFormSheet(
              maxHeightFactor: 0.88,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate ${template.title}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    key: const ValueKey('report-format-dropdown'),
                    value: selectedFormat,
                    label: l10n.commonFormat,
                    prefixIcon: Icons.file_present_rounded,
                    items: template.formats
                        .map(
                          (format) => DropdownMenuItem<String>(
                            value: format,
                            child: Text(format),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedFormat = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsIncludeCharts),
                    value: includeCharts,
                    onChanged: (value) =>
                        setSheetState(() => includeCharts = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsIncludeTransactions),
                    value: includeDetailedTransactions,
                    onChanged: (value) => setSheetState(
                        () => includeDetailedTransactions = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsIncludeBudgets),
                    value: includeBudgets,
                    onChanged: (value) =>
                        setSheetState(() => includeBudgets = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsIncludeSubscriptions),
                    value: includeSubscriptions,
                    onChanged: (value) =>
                        setSheetState(() => includeSubscriptions = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsIncludeSavings),
                    value: includeSavingsGoals,
                    onChanged: (value) =>
                        setSheetState(() => includeSavingsGoals = value),
                  ),
                  if (_isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: AppLottieView(
                        assetPath: 'assets/animations/report_generation.json',
                        width: 64,
                        height: 64,
                        repeat: true,
                        animate: true,
                        fallbackIcon: Icons.sync_rounded,
                      ),
                    ),
                ],
              ),
              actions: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.cancel,
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('confirm-generate-report'),
                        label: l10n.commonGenerate,
                        icon: Icons.play_arrow_rounded,
                        onPressed: _isGenerating
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await _handleGenerate(
                                  template,
                                  selectedFormat,
                                  ReportGenerationOptions(
                                    includeCharts: includeCharts,
                                    includeDetailedTransactions:
                                        includeDetailedTransactions,
                                    includeBudgets: includeBudgets,
                                    includeSubscriptions: includeSubscriptions,
                                    includeSavingsGoals: includeSavingsGoals,
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleGenerate(
    _AvailableReportTemplate template,
    String format,
    ReportGenerationOptions options,
  ) async {
    AppFeedbackService.showInfo(context, 'Generating report...');
    _trackActivity(
      title: '${template.title} processing',
      status: _ReportActivityStatus.processing,
      format: format,
      icon: Icons.sync_rounded,
    );

    if (widget.generationExecutor != null) {
      setState(() {
        _isGenerating = true;
      });
      try {
        await widget.generationExecutor!(template.reportKey, format, options);
        if (!mounted) return;
        _trackGeneratedReport(
          reportKey: template.reportKey,
          title: template.title,
          format: format,
          filename:
              '${template.reportKey}_${DateTime.now().millisecondsSinceEpoch}.${format.toLowerCase()}',
          icon: template.icon,
          fileSizeBytes: 0,
        );
        _trackActivity(
          title: '${template.title} generated',
          status: _ReportActivityStatus.generated,
          format: format,
          icon: template.icon,
        );
        AppFeedbackService.showSuccess(
            context, 'Report generated successfully');
      } catch (e, st) {
        await ErrorMonitor.captureException(e, st,
            context: 'report:${template.reportKey}:$format');
        if (!mounted) return;
        _trackFailedReport(
          reportKey: template.reportKey,
          title: template.title,
          format: format,
          icon: template.icon,
        );
        AppFeedbackService.showError(
          context, 'Report generation failed: ${AppErrorMapper.from(e)}');
      } finally {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
        }
      }
      return;
    }

    try {
      await _runDefaultGeneration(template, format);
      if (!mounted) return;
      _trackActivity(
        title: '${template.title} generated',
        status: _ReportActivityStatus.generated,
        format: format,
        icon: template.icon,
      );
      AppFeedbackService.showSuccess(context, 'Report generated successfully');
    } catch (e, st) {
      await ErrorMonitor.captureException(e, st,
          context: 'report:${template.reportKey}:$format');
      if (!mounted) return;
      _trackFailedReport(
        reportKey: template.reportKey,
        title: template.title,
        format: format,
        icon: template.icon,
      );
      AppFeedbackService.showError(
          context, 'Report generation failed: ${AppErrorMapper.from(e)}');
    }
  }

  Future<void> _runDefaultGeneration(
    _AvailableReportTemplate template,
    String format,
  ) async {
    switch (template.reportKey) {
      case 'financial_summary':
        if (format == 'PDF') {
          await _generateFinancialSummary();
          return;
        }
        if (format == 'CSV') {
          await _generateTransactionHistory();
          return;
        }
        AppFeedbackService.showWarning(
          context,
          'XLSX is exported as CSV in this build.',
        );
        await _generateTransactionHistory();
        return;
      case 'transaction_history':
        await _generateTransactionHistory();
        return;
      case 'budget_analysis':
        await _generateBudgetAnalysis();
        return;
      case 'subscription_costs':
        await _generateSubscriptionReport();
        return;
      case 'savings_progress':
      case 'cashflow_forecast':
      case 'category_insights':
        await _generateFinancialSummary();
        return;
      case 'tax_ready_export':
        await _exportAsCSV();
        return;
    }
  }

  void _openExportWorkflowSheet() {
    final l10n = AppLocalizations.of(context)!;
    AppFormSheet.show(
      context,
      builder: (sheetContext) => AppFormSheet(
        maxHeightFactor: 0.44,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n.reportsExportFinancialSummaryPdf),
              onTap: () {
                Navigator.of(sheetContext).pop();
                AppFeedbackService.showInfo(context, 'Export started');
                _generateFinancialSummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: Text(l10n.reportsExportCompleteCsv),
              onTap: () {
                Navigator.of(sheetContext).pop();
                AppFeedbackService.showInfo(context, 'Export started');
                _exportAsCSV();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyQuickFilter(_QuickRangeFilter filter) {
    final now = DateTime.now();
    setState(() {
      _quickRangeFilter = filter;
      switch (filter) {
        case _QuickRangeFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _startDate =
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          _endDate = now;
        case _QuickRangeFilter.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
        case _QuickRangeFilter.lastMonth:
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
        case _QuickRangeFilter.last3Months:
          _startDate = DateTime(now.year, now.month - 3, 1);
          _endDate = now;
        case _QuickRangeFilter.thisYear:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
        case _QuickRangeFilter.custom:
          break;
      }
    });
    AppFeedbackService.showInfo(context, 'Filter applied');
  }

  List<_ReportActivityEntry> _filteredActivities() {
    return _activities.where((entry) {
      switch (_activityFilter) {
        case _ReportActivityFilter.all:
          return true;
        case _ReportActivityFilter.generated:
          return entry.status == _ReportActivityStatus.generated ||
              entry.status == _ReportActivityStatus.exported ||
              entry.status == _ReportActivityStatus.downloaded;
        case _ReportActivityFilter.failed:
          return entry.status == _ReportActivityStatus.failed;
        case _ReportActivityFilter.scheduled:
          return entry.status == _ReportActivityStatus.scheduled;
      }
    }).toList(growable: false);
  }

  void _trackActivity({
    required String title,
    required _ReportActivityStatus status,
    required String format,
    required IconData icon,
  }) {
    setState(() {
      _activities.insert(
        0,
        _ReportActivityEntry(
          title: title,
          status: status,
          format: format,
          icon: icon,
          at: DateTime.now(),
        ),
      );
      if (_activities.length > 20) {
        _activities.removeLast();
      }
      _recomputeSummary();
    });
  }

  void _trackGeneratedReport({
    required String reportKey,
    required String title,
    required String format,
    required String filename,
    required IconData icon,
    required int fileSizeBytes,
  }) {
    final now = DateTime.now();
    setState(() {
      _lastGeneratedAt = now;
      _reportCounts.update(reportKey, (value) => value + 1, ifAbsent: () => 1);
      _generatedReports.insert(
        0,
        _GeneratedReportEntry(
          reportKey: reportKey,
          title: title,
          format: format,
          filename: filename,
          generatedAt: now,
          icon: icon,
          status: _ReportRunStatus.generated,
          fileSizeBytes: fileSizeBytes,
        ),
      );
      if (_generatedReports.length > 12) {
        _generatedReports.removeLast();
      }
      _recomputeSummary();
    });
  }

  void _trackFailedReport({
    required String reportKey,
    required String title,
    required String format,
    required IconData icon,
  }) {
    setState(() {
      _generatedReports.insert(
        0,
        _GeneratedReportEntry(
          reportKey: reportKey,
          title: title,
          format: format,
          filename: 'failed',
          generatedAt: DateTime.now(),
          icon: icon,
          status: _ReportRunStatus.failed,
          fileSizeBytes: 0,
        ),
      );
      if (_generatedReports.length > 12) {
        _generatedReports.removeLast();
      }
      _activities.insert(
        0,
        _ReportActivityEntry(
          title: '$title failed',
          status: _ReportActivityStatus.failed,
          format: format,
          icon: icon,
          at: DateTime.now(),
        ),
      );
      if (_activities.length > 20) {
        _activities.removeLast();
      }
      _recomputeSummary();
    });
  }

  void _recomputeSummary() {
    final now = DateTime.now();
    var thisMonth = 0;
    for (final entry in _generatedReports) {
      if (entry.generatedAt.year == now.year &&
          entry.generatedAt.month == now.month &&
          entry.status == _ReportRunStatus.generated) {
        thisMonth += 1;
      }
    }

    _summary = _ReportsSummary(
      totalGenerated: _generatedReports
          .where((e) => e.status == _ReportRunStatus.generated)
          .length,
      generatedThisMonth: thisMonth,
      lastExportAt: _lastGeneratedAt,
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
        _quickRangeFilter = _QuickRangeFilter.custom;
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      if (context.mounted) {
        AppFeedbackService.showInfo(context, 'Filter applied');
      }
    }
  }

  List<_AvailableReportTemplate> _buildAvailableReportTemplates(
      AppLocalizations l10n) {
    return [
      _AvailableReportTemplate(
        reportKey: 'financial_summary',
        title: l10n.reportTypeFinancialSummary,
        description:
            'High-level financial performance with balances and trends.',
        icon: Icons.analytics_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~15s',
      ),
      _AvailableReportTemplate(
        reportKey: 'transaction_history',
        title: l10n.reportTypeTransactionHistory,
        description: 'Full transaction timeline with categories and notes.',
        icon: Icons.receipt_long_rounded,
        formats: ['CSV', 'PDF', 'XLSX'],
        estimatedDurationLabel: '~10s',
      ),
      _AvailableReportTemplate(
        reportKey: 'budget_analysis',
        title: l10n.reportTypeBudgetAnalysis,
        description: 'Budget utilization and over/under allocation insights.',
        icon: Icons.pie_chart_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~20s',
      ),
      _AvailableReportTemplate(
        reportKey: 'subscription_costs',
        title: l10n.reportTypeSubscriptionCosts,
        description: 'Recurring services cost review and renewal overview.',
        icon: Icons.subscriptions_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~12s',
      ),
      _AvailableReportTemplate(
        reportKey: 'savings_progress',
        title: l10n.reportTypeSavingsProgress,
        description: 'Savings trajectory against targets and monthly cadence.',
        icon: Icons.savings_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~12s',
      ),
      _AvailableReportTemplate(
        reportKey: 'cashflow_forecast',
        title: l10n.reportTypeCashflowForecast,
        description: 'Projected short-term inflow and outflow forecast.',
        icon: Icons.show_chart_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~16s',
      ),
      _AvailableReportTemplate(
        reportKey: 'category_insights',
        title: l10n.reportTypeCategoryInsights,
        description: 'Category-level spend concentration and changes.',
        icon: Icons.grid_view_rounded,
        formats: ['PDF', 'CSV', 'XLSX'],
        estimatedDurationLabel: '~14s',
      ),
      _AvailableReportTemplate(
        reportKey: 'tax_ready_export',
        title: l10n.reportTypeTaxReady,
        description:
            'Consolidated export package for tax preparation workflows.',
        icon: Icons.request_page_rounded,
        formats: ['CSV', 'XLSX', 'PDF'],
        estimatedDurationLabel: '~18s',
      ),
    ];
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

  /// L-2 FIX: Show a privacy warning before sharing any report file.
  /// Financial exports contain sensitive data; users should be reminded
  /// before the OS share sheet hands the file to a third-party app.
  Future<bool> _confirmShare(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx)!;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(l10n.reportsShareDataTitle),
          ],
        ),
        content: const Text(
          'This file contains sensitive financial information. '
          'Only share it with trusted recipients via secure channels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.commonShare),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _warnAndShare(XFile file, {required String text}) async {
    if (!mounted) return;
    final ok = await _confirmShare(context);
    if (!ok || !mounted) return;
    // sharePositionOrigin is required for the iPad popover anchor; omitting it
    // throws there. Harmless on iPhone.
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        text: text,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  Future<void> _generateFinancialSummary() async {
    _beginReportGeneration('Generating financial summary...');
    final l10n = AppLocalizations.of(context)!;

    try {
      final pdfTheme = await _buildPdfTheme();
      final pdf = pw.Document();
      final appCurrency = ref.read(appCurrencyControllerProvider);
      final appCurrencySymbol = CurrencyUtils.symbol(appCurrency);

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

      final subscriptionCosts =
          subscriptions.fold<double>(0, (sum, s) => sum + s.monthlyCost);

      final budgetUtilization = <String, double>{};
      for (final budget in budgets) {
        final spent = await ref.read(budgetSpendingProvider(
          category: budget.category,
          start: _startDate,
          end: _endDate,
        ).future);
        budgetUtilization[budget.category] = spent / budget.limitAmount;
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

      final output = await _getOutputFile('financial_summary.pdf');
      await output.writeAsBytes(await pdf.save());
      final fileSize = await output.length();

      _trackGeneratedReport(
        reportKey: 'financial_summary',
        title: l10n.reportsFinancialSummary(appCurrency.toUpperCase()),
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.analytics_rounded,
        fileSizeBytes: fileSize,
      );

      await _warnAndShare(XFile(output.path),
          text: l10n.reportsShareFinancialSummary);

      _trackActivity(
        title: l10n.reportShared(l10n.reportTypeFinancialSummary),
        status: _ReportActivityStatus.exported,
        format: 'PDF',
        icon: Icons.share_rounded,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(context, l10n.reportsPdfGeneratedShared);
      }
    } catch (e) {
      final appCurrency = ref.read(appCurrencyControllerProvider);
      _trackFailedReport(
        reportKey: 'financial_summary',
        title: l10n.reportsFinancialSummary(appCurrency.toUpperCase()),
        format: 'PDF',
        icon: Icons.analytics_rounded,
      );
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(AppErrorMapper.from(e)),
        );
      }
      rethrow;
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
      final fileSize = await output.length();

      _trackGeneratedReport(
        reportKey: 'transaction_history',
        title: l10n.reportsTransactionHistory,
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.receipt_long_rounded,
        fileSizeBytes: fileSize,
      );

      await _warnAndShare(XFile(output.path),
          text: l10n.reportsShareTransactionHistory);

      _trackActivity(
        title: l10n.reportShared(l10n.reportTypeTransactionHistory),
        status: _ReportActivityStatus.exported,
        format: 'CSV',
        icon: Icons.share_rounded,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsTransactionHistoryExported,
        );
      }
    } catch (e) {
      _trackFailedReport(
        reportKey: 'transaction_history',
        title: l10n.reportsTransactionHistory,
        format: 'CSV',
        icon: Icons.receipt_long_rounded,
      );
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorExportingData(AppErrorMapper.from(e)),
        );
      }
      rethrow;
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
      final fileSize = await output.length();

      _trackGeneratedReport(
        reportKey: 'budget_analysis',
        title: l10n.reportsBudgetAnalysis,
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.pie_chart_rounded,
        fileSizeBytes: fileSize,
      );

      await _warnAndShare(XFile(output.path),
          text: l10n.reportsShareBudgetAnalysis);

      _trackActivity(
        title: l10n.reportShared(l10n.reportTypeBudgetAnalysis),
        status: _ReportActivityStatus.exported,
        format: 'PDF',
        icon: Icons.share_rounded,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsBudgetAnalysisGenerated,
        );
      }
    } catch (e) {
      _trackFailedReport(
        reportKey: 'budget_analysis',
        title: l10n.reportsBudgetAnalysis,
        format: 'PDF',
        icon: Icons.pie_chart_rounded,
      );
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(AppErrorMapper.from(e)),
        );
      }
      rethrow;
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
      final fileSize = await output.length();

      _trackGeneratedReport(
        reportKey: 'subscription_costs',
        title: l10n.reportsSubscriptionCosts,
        format: 'PDF',
        filename: output.path.split('/').last,
        icon: Icons.subscriptions_rounded,
        fileSizeBytes: fileSize,
      );

      await _warnAndShare(XFile(output.path),
          text: l10n.reportsShareSubscriptionReport);

      _trackActivity(
        title: l10n.reportShared(l10n.reportTypeSubscriptionCosts),
        status: _ReportActivityStatus.exported,
        format: 'PDF',
        icon: Icons.share_rounded,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsSubscriptionReportGenerated,
        );
      }
    } catch (e) {
      _trackFailedReport(
        reportKey: 'subscription_costs',
        title: l10n.reportsSubscriptionCosts,
        format: 'PDF',
        icon: Icons.subscriptions_rounded,
      );
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorGenerating(AppErrorMapper.from(e)),
        );
      }
      rethrow;
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
      final fileSize = await output.length();

      _trackGeneratedReport(
        reportKey: 'tax_ready_export',
        title: l10n.reportsCompleteDataExportTitle,
        format: 'CSV',
        filename: output.path.split('/').last,
        icon: Icons.table_chart_rounded,
        fileSizeBytes: fileSize,
      );

      await _warnAndShare(XFile(output.path),
          text: l10n.reportsShareCompleteDataExport);

      _trackActivity(
        title: l10n.reportShared(l10n.reportTypeCompleteExport),
        status: _ReportActivityStatus.exported,
        format: 'CSV',
        icon: Icons.share_rounded,
      );

      if (mounted) {
        AppFeedbackService.showSuccess(
          context,
          l10n.reportsCompleteDataExportCreated,
        );
      }
    } catch (e) {
      _trackFailedReport(
        reportKey: 'tax_ready_export',
        title: l10n.reportsCompleteDataExportTitle,
        format: 'CSV',
        icon: Icons.table_chart_rounded,
      );
      if (mounted) {
        AppFeedbackService.showError(
          context,
          l10n.reportsErrorExportingData(AppErrorMapper.from(e)),
        );
      }
      rethrow;
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

class _AvailableReportTemplate {
  const _AvailableReportTemplate({
    required this.reportKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.formats,
    required this.estimatedDurationLabel,
  });

  final String reportKey;
  final String title;
  final String description;
  final IconData icon;
  final List<String> formats;
  final String estimatedDurationLabel;
}

class _GeneratedReportEntry {
  const _GeneratedReportEntry({
    required this.reportKey,
    required this.title,
    required this.format,
    required this.filename,
    required this.generatedAt,
    required this.icon,
    required this.status,
    required this.fileSizeBytes,
  });

  final String reportKey;
  final String title;
  final String format;
  final String filename;
  final DateTime generatedAt;
  final IconData icon;
  final _ReportRunStatus status;
  final int fileSizeBytes;

  String get fileSizeLabel {
    if (fileSizeBytes <= 0) return 'size unavailable';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}

class _ReportActivityEntry {
  const _ReportActivityEntry({
    required this.title,
    required this.status,
    required this.format,
    required this.icon,
    required this.at,
  });

  final String title;
  final _ReportActivityStatus status;
  final String format;
  final IconData icon;
  final DateTime at;
}

enum _ReportRunStatus { generated, failed }

enum _ReportActivityStatus {
  generated,
  exported,
  processing,
  failed,
  scheduled,
  downloaded,
}

extension _ReportActivityStatusX on _ReportActivityStatus {
  String get label {
    switch (this) {
      case _ReportActivityStatus.generated:
        return 'Generated';
      case _ReportActivityStatus.exported:
        return 'Exported';
      case _ReportActivityStatus.processing:
        return 'Processing';
      case _ReportActivityStatus.failed:
        return 'Failed';
      case _ReportActivityStatus.scheduled:
        return 'Scheduled';
      case _ReportActivityStatus.downloaded:
        return 'Generated';
    }
  }

  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case _ReportActivityStatus.generated:
        return const Color(0xFF0F9D58);
      case _ReportActivityStatus.exported:
        return scheme.primary;
      case _ReportActivityStatus.processing:
        return scheme.tertiary;
      case _ReportActivityStatus.failed:
        return scheme.error;
      case _ReportActivityStatus.scheduled:
        return const Color(0xFF6F62F4);
      case _ReportActivityStatus.downloaded:
        return scheme.primary;
    }
  }
}

enum _ReportActivityFilter { all, generated, failed, scheduled }

extension _ReportActivityFilterX on _ReportActivityFilter {
  String get label {
    switch (this) {
      case _ReportActivityFilter.all:
        return 'All';
      case _ReportActivityFilter.generated:
        return 'Generated';
      case _ReportActivityFilter.failed:
        return 'Failed';
      case _ReportActivityFilter.scheduled:
        return 'Scheduled';
    }
  }

  String get key {
    switch (this) {
      case _ReportActivityFilter.all:
        return 'all';
      case _ReportActivityFilter.generated:
        return 'generated';
      case _ReportActivityFilter.failed:
        return 'failed';
      case _ReportActivityFilter.scheduled:
        return 'scheduled';
    }
  }
}

enum _QuickRangeFilter {
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

extension _QuickRangeFilterX on _QuickRangeFilter {
  String get label {
    switch (this) {
      case _QuickRangeFilter.thisWeek:
        return 'This Week';
      case _QuickRangeFilter.thisMonth:
        return 'This Month';
      case _QuickRangeFilter.lastMonth:
        return 'Last Month';
      case _QuickRangeFilter.last3Months:
        return 'Last 3 Months';
      case _QuickRangeFilter.thisYear:
        return 'This Year';
      case _QuickRangeFilter.custom:
        return 'Custom';
    }
  }

  String get key {
    switch (this) {
      case _QuickRangeFilter.thisWeek:
        return 'this-week';
      case _QuickRangeFilter.thisMonth:
        return 'this-month';
      case _QuickRangeFilter.lastMonth:
        return 'last-month';
      case _QuickRangeFilter.last3Months:
        return 'last-3-months';
      case _QuickRangeFilter.thisYear:
        return 'this-year';
      case _QuickRangeFilter.custom:
        return 'custom';
    }
  }
}

class _ReportsSummary {
  const _ReportsSummary({
    required this.totalGenerated,
    required this.generatedThisMonth,
    required this.lastExportAt,
  });

  const _ReportsSummary.empty()
      : totalGenerated = 0,
        generatedThisMonth = 0,
        lastExportAt = null;

  final int totalGenerated;
  final int generatedThisMonth;
  final DateTime? lastExportAt;
}
