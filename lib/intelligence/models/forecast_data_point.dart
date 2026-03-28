import 'package:smartbudget/intelligence/models/money.dart';

class ForecastDataPoint {
  final DateTime date;
  final Money actual;
  final Money predicted;

  const ForecastDataPoint({
    required this.date,
    required this.actual,
    required this.predicted,
  });
}
