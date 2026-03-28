import 'package:smartbudget/data/datasources/local/app_database.dart'
    show SecuritySetting;
import 'package:smartbudget/domain/entities/subscription.dart';
import 'package:smartbudget/intelligence/models/forecast_data_point.dart';
import 'package:smartbudget/intelligence/models/insight.dart';
import 'package:smartbudget/intelligence/analyzers/spending_analyzer.dart';
import 'package:smartbudget/intelligence/predictors/cashflow_predictor.dart';

class InsightResults {
  final String currency;
  final List<Insight> insights;
  final List<ForecastDataPoint> forecastSeries;
  final SpendingProfile spendingProfile;
  final CashflowPrediction forecast;
  final List<Subscription> subscriptions;
  final SecuritySetting? securitySetting;

  const InsightResults({
    required this.currency,
    required this.insights,
    required this.forecastSeries,
    required this.spendingProfile,
    required this.forecast,
    required this.subscriptions,
    required this.securitySetting,
  });
}
