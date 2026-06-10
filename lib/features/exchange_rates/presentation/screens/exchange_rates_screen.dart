import 'package:fl_chart/fl_chart.dart';
import 'package:smartbudget/components/charts/app_finance_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/core/providers/core_providers.dart';
import 'package:smartbudget/core/services/currency_service.dart';
import 'package:smartbudget/core/services/exchange_rate_service.dart';
import 'package:smartbudget/core/theme/input_styles.dart';
import 'package:smartbudget/core/theme/app_surfaces.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/components/forms/form_components.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class ExchangeRatesScreen extends ConsumerStatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  ConsumerState<ExchangeRatesScreen> createState() =>
      _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends ConsumerState<ExchangeRatesScreen> {
  static const _currencies = CurrencyService.supportedCurrencyCodes;

  final _amountController = TextEditingController(text: '100');
  late String _baseCurrency;
  late String _targetCurrency;
  bool _isLoading = false;
  bool _isAppBarScrolled = false;
  ExchangeRateQuote? _quote;
  List<ExchangeRatePoint> _trendPoints = const <ExchangeRatePoint>[];
  String? _error;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  void initState() {
    super.initState();
    final appCurrency = ref.read(appCurrencyControllerProvider);
    _baseCurrency = appCurrency;
    _targetCurrency = appCurrency == 'USD' ? 'EUR' : 'USD';
    _fetchRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchRate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(exchangeRateServiceProvider);
      final quote = await service.fetchRate(
        base: _baseCurrency,
        target: _targetCurrency,
      );
      final trend = await service.fetchTrend(
        base: _baseCurrency,
        target: _targetCurrency,
        days: 7,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _trendPoints = trend;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.exchangeUnableToFetch;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _baseCurrency;
      _baseCurrency = _targetCurrency;
      _targetCurrency = temp;
    });
    _fetchRate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rate = _quote?.rate ?? 0;
    final converted = amount * rate;
    final formatter = NumberFormat.currency(symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: l10n.navExchangeRates,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
              alpha: _isAppBarScrolled ? 0.88 : 0,
            ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'exchange-rates-appbar-blur-on',
          offKey: 'exchange-rates-appbar-blur-off',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppSurfaces.elevated(context, radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.currency_exchange_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.exchangeLiveRateChecker,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.exchangeRateProviderInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: InputStyles.inputTextStyle(Theme.of(context)),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ModernSelect<String>(
                          key: ValueKey('base-$_baseCurrency'),
                          value: _baseCurrency,
                          label: l10n.exchangeRatesFrom,
                          items: _currencies
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _baseCurrency = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _isLoading ? null : _swapCurrencies,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        tooltip: l10n.exchangeRatesSwap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ModernSelect<String>(
                          key: ValueKey('target-$_targetCurrency'),
                          value: _targetCurrency,
                          label: l10n.exchangeRatesTo,
                          items: _currencies
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _targetCurrency = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _fetchRate,
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(l10n.exchangeRatesCheckRate),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppSurfaces.elevated(context, radius: 18),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.exchangeRatesConversionResult,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '1 $_baseCurrency = ${rate.toStringAsFixed(4)} $_targetCurrency',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${formatter.format(amount)} $_baseCurrency = ${formatter.format(converted)} $_targetCurrency',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (_quote != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.exchangeRatesRateDate(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_quote!.date)),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                            if (_trendPoints.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.exchangeRatesTrend7Days,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ChartEntrance(
                                builder: (ctx, _) => SizedBox(
                                height: 140,
                                child: LineChart(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOutCubic,
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 24,
                                          interval:
                                              _trendPoints.length > 4 ? 2 : 1,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >= _trendPoints.length) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 6),
                                              child: Text(
                                                DateFormat('MMMd').format(
                                                    _trendPoints[index].date),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _trendPoints
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => FlSpot(
                                                entry.key.toDouble(),
                                                entry.value.rate,
                                              ),
                                            )
                                            .toList(),
                                        isCurved: true,
                                        barWidth: 3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ), // SizedBox
                              ), // ChartEntrance
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
