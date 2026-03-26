import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get accountId => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get recurrence =>
      intEnum<TransactionRecurrence>().withDefault(const Constant(0))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Accounts extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get type => intEnum<AccountType>()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get category => text()();
  RealColumn get limitAmount => real()();
  TextColumn get currency => text()();
  IntColumn get period => intEnum<BudgetPeriod>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class SavingsGoals extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get priority => intEnum<GoalPriority>()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Enums
enum TransactionType { income, expense, transfer }

enum AccountType { cash, bank, mobileMoney, creditCard, investment }

enum BudgetPeriod { weekly, monthly, yearly }

enum TransactionRecurrence { none, daily, weekly, monthly, yearly }

enum GoalPriority { low, medium, high, critical }

String _generateUuid() {
  // Simple UUID v4 generator
  return '${_randomHex(8)}-${_randomHex(4)}-4${_randomHex(3)}-${_randomHex(4)}-${_randomHex(12)}';
}

String _randomHex(int length) {
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  return random.substring(random.length - length);
}
