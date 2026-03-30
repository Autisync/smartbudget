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
  DateTimeColumn get lastGeneratedAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
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
  IntColumn get alertThreshold => integer().withDefault(const Constant(80))();
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
  BoolColumn get autoAllocate => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  IntColumn get billingCycle => intEnum<BillingCycle>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextBillingDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get category => text()();
  IntColumn get importance => intEnum<SubscriptionImportance>()
      .withDefault(const Constant(1))(); // 0=low, 1=medium, 2=high, 3=critical
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get website => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Enums
enum TransactionType { income, expense, transfer }

enum AccountType { cash, bank, mobileMoney, creditCard, investment }

enum BudgetPeriod { weekly, monthly, yearly }

enum TransactionRecurrence { none, daily, weekly, monthly, yearly }

enum GoalPriority { low, medium, high, critical }

enum BillingCycle { weekly, monthly, quarterly, yearly }

enum SubscriptionImportance { low, medium, high, critical }

enum AuthLogType { biometric, pin, password }

enum AuthStatus { success, failed, lockedOut }

class Devices extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get deviceName => text()(); // e.g., "iPhone 14 Pro", "MacBook Air"
  TextColumn get deviceId => text().unique()(); // Platform-specific device ID
  TextColumn get platform => text()(); // iOS, Android, macOS, Windows
  TextColumn get osVersion => text()();
  TextColumn get appVersion => text()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastAuthAt => dateTime()();
  DateTimeColumn get registeredAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AuthLogs extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  TextColumn get deviceId => text()(); // FK to Devices
  IntColumn get authType =>
      intEnum<AuthLogType>()(); // biometric, pin, password
  IntColumn get status => intEnum<AuthStatus>()(); // success, failed, lockedOut
  TextColumn get ipAddress => text().nullable()();
  TextColumn get userAgent => text().nullable()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
        {deviceId, timestamp},
      ];
}

class SecuritySettings extends Table {
  TextColumn get id => text().clientDefault(() => _generateUuid())();
  IntColumn get sessionTimeout =>
      integer().withDefault(const Constant(300))(); // 5 minutes in seconds
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pinEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get maxFailedAttempts => integer().withDefault(const Constant(5))();
  IntColumn get lockoutDuration =>
      integer().withDefault(const Constant(900))(); // 15 minutes in seconds
  DateTimeColumn get lastSecurityUpdate =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

String _generateUuid() {
  // Simple UUID v4 generator
  return '${_randomHex(8)}-${_randomHex(4)}-4${_randomHex(3)}-${_randomHex(4)}-${_randomHex(12)}';
}

String _randomHex(int length) {
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  return random.substring(random.length - length);
}
