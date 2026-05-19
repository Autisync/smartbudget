class Money {
  final double amount;
  final String currency;
  final double baseAmount;

  const Money({
    required this.amount,
    required this.currency,
    required this.baseAmount,
  });

  factory Money.of(
    double amount,
    String currency, {
    double? baseAmount,
  }) {
    return Money(
      amount: amount,
      currency: currency,
      baseAmount: baseAmount ?? amount,
    );
  }

  String formatted(String symbol) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}




