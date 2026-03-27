// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionRecurrence, int>
      recurrence = GeneratedColumn<int>('recurrence', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<TransactionRecurrence>(
              $TransactionsTable.$converterrecurrence);
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'is_recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastGeneratedAtMeta =
      const VerificationMeta('lastGeneratedAt');
  @override
  late final GeneratedColumn<DateTime> lastGeneratedAt =
      GeneratedColumn<DateTime>('last_generated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextDueAtMeta =
      const VerificationMeta('nextDueAt');
  @override
  late final GeneratedColumn<DateTime> nextDueAt = GeneratedColumn<DateTime>(
      'next_due_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        amount,
        currency,
        type,
        category,
        date,
        note,
        recurrence,
        isRecurring,
        lastGeneratedAt,
        nextDueAt,
        createdAt,
        updatedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['is_recurring']!, _isRecurringMeta));
    }
    if (data.containsKey('last_generated_at')) {
      context.handle(
          _lastGeneratedAtMeta,
          lastGeneratedAt.isAcceptableOrUnknown(
              data['last_generated_at']!, _lastGeneratedAtMeta));
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
          _nextDueAtMeta,
          nextDueAt.isAcceptableOrUnknown(
              data['next_due_at']!, _nextDueAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      type: $TransactionsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      recurrence: $TransactionsTable.$converterrecurrence.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}recurrence'])!),
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!,
      lastGeneratedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_generated_at']),
      nextDueAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_due_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
  static JsonTypeConverter2<TransactionRecurrence, int, int>
      $converterrecurrence = const EnumIndexConverter<TransactionRecurrence>(
          TransactionRecurrence.values);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String accountId;
  final double amount;
  final String currency;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final TransactionRecurrence recurrence;
  final bool isRecurring;
  final DateTime? lastGeneratedAt;
  final DateTime? nextDueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  const Transaction(
      {required this.id,
      required this.accountId,
      required this.amount,
      required this.currency,
      required this.type,
      required this.category,
      required this.date,
      this.note,
      required this.recurrence,
      required this.isRecurring,
      this.lastGeneratedAt,
      this.nextDueAt,
      required this.createdAt,
      required this.updatedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    {
      map['type'] =
          Variable<int>($TransactionsTable.$convertertype.toSql(type));
    }
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['recurrence'] = Variable<int>(
          $TransactionsTable.$converterrecurrence.toSql(recurrence));
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || lastGeneratedAt != null) {
      map['last_generated_at'] = Variable<DateTime>(lastGeneratedAt);
    }
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      amount: Value(amount),
      currency: Value(currency),
      type: Value(type),
      category: Value(category),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      recurrence: Value(recurrence),
      isRecurring: Value(isRecurring),
      lastGeneratedAt: lastGeneratedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGeneratedAt),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      type: $TransactionsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      recurrence: $TransactionsTable.$converterrecurrence
          .fromJson(serializer.fromJson<int>(json['recurrence'])),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      lastGeneratedAt: serializer.fromJson<DateTime?>(json['lastGeneratedAt']),
      nextDueAt: serializer.fromJson<DateTime?>(json['nextDueAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'type': serializer
          .toJson<int>($TransactionsTable.$convertertype.toJson(type)),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String?>(note),
      'recurrence': serializer.toJson<int>(
          $TransactionsTable.$converterrecurrence.toJson(recurrence)),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'lastGeneratedAt': serializer.toJson<DateTime?>(lastGeneratedAt),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Transaction copyWith(
          {String? id,
          String? accountId,
          double? amount,
          String? currency,
          TransactionType? type,
          String? category,
          DateTime? date,
          Value<String?> note = const Value.absent(),
          TransactionRecurrence? recurrence,
          bool? isRecurring,
          Value<DateTime?> lastGeneratedAt = const Value.absent(),
          Value<DateTime?> nextDueAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isSynced}) =>
      Transaction(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        type: type ?? this.type,
        category: category ?? this.category,
        date: date ?? this.date,
        note: note.present ? note.value : this.note,
        recurrence: recurrence ?? this.recurrence,
        isRecurring: isRecurring ?? this.isRecurring,
        lastGeneratedAt: lastGeneratedAt.present
            ? lastGeneratedAt.value
            : this.lastGeneratedAt,
        nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      lastGeneratedAt: data.lastGeneratedAt.present
          ? data.lastGeneratedAt.value
          : this.lastGeneratedAt,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('recurrence: $recurrence, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('lastGeneratedAt: $lastGeneratedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      amount,
      currency,
      type,
      category,
      date,
      note,
      recurrence,
      isRecurring,
      lastGeneratedAt,
      nextDueAt,
      createdAt,
      updatedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.type == this.type &&
          other.category == this.category &&
          other.date == this.date &&
          other.note == this.note &&
          other.recurrence == this.recurrence &&
          other.isRecurring == this.isRecurring &&
          other.lastGeneratedAt == this.lastGeneratedAt &&
          other.nextDueAt == this.nextDueAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<TransactionType> type;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<String?> note;
  final Value<TransactionRecurrence> recurrence;
  final Value<bool> isRecurring;
  final Value<DateTime?> lastGeneratedAt;
  final Value<DateTime?> nextDueAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.lastGeneratedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required double amount,
    required String currency,
    required TransactionType type,
    required String category,
    required DateTime date,
    this.note = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.lastGeneratedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        amount = Value(amount),
        currency = Value(currency),
        type = Value(type),
        category = Value(category),
        date = Value(date);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<int>? type,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<int>? recurrence,
    Expression<bool>? isRecurring,
    Expression<DateTime>? lastGeneratedAt,
    Expression<DateTime>? nextDueAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (recurrence != null) 'recurrence': recurrence,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (lastGeneratedAt != null) 'last_generated_at': lastGeneratedAt,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<double>? amount,
      Value<String>? currency,
      Value<TransactionType>? type,
      Value<String>? category,
      Value<DateTime>? date,
      Value<String?>? note,
      Value<TransactionRecurrence>? recurrence,
      Value<bool>? isRecurring,
      Value<DateTime?>? lastGeneratedAt,
      Value<DateTime?>? nextDueAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
      isRecurring: isRecurring ?? this.isRecurring,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($TransactionsTable.$convertertype.toSql(type.value));
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(
          $TransactionsTable.$converterrecurrence.toSql(recurrence.value));
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (lastGeneratedAt.present) {
      map['last_generated_at'] = Variable<DateTime>(lastGeneratedAt.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('recurrence: $recurrence, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('lastGeneratedAt: $lastGeneratedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, balance, currency, isActive, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $AccountsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, int, int> $convertertype =
      const EnumIndexConverter<AccountType>(AccountType.values);
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  const Account(
      {required this.id,
      required this.name,
      required this.type,
      required this.balance,
      required this.currency,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($AccountsTable.$convertertype.toSql(type));
    }
    map['balance'] = Variable<double>(balance);
    map['currency'] = Variable<String>(currency);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      balance: Value(balance),
      currency: Value(currency),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      balance: serializer.fromJson<double>(json['balance']),
      currency: serializer.fromJson<String>(json['currency']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type':
          serializer.toJson<int>($AccountsTable.$convertertype.toJson(type)),
      'balance': serializer.toJson<double>(balance),
      'currency': serializer.toJson<String>(currency),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith(
          {String? id,
          String? name,
          AccountType? type,
          double? balance,
          String? currency,
          bool? isActive,
          DateTime? createdAt}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      balance: data.balance.present ? data.balance.value : this.balance,
      currency: data.currency.present ? data.currency.value : this.currency,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, balance, currency, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.balance == this.balance &&
          other.currency == this.currency &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<double> balance;
  final Value<String> currency;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.balance = const Value.absent(),
    this.currency = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountType type,
    this.balance = const Value.absent(),
    required String currency,
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        currency = Value(currency);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<double>? balance,
    Expression<String>? currency,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (balance != null) 'balance': balance,
      if (currency != null) 'currency': currency,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<AccountType>? type,
      Value<double>? balance,
      Value<String>? currency,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($AccountsTable.$convertertype.toSql(type.value));
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _limitAmountMeta =
      const VerificationMeta('limitAmount');
  @override
  late final GeneratedColumn<double> limitAmount = GeneratedColumn<double>(
      'limit_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<BudgetPeriod, int> period =
      GeneratedColumn<int>('period', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<BudgetPeriod>($BudgetsTable.$converterperiod);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _alertThresholdMeta =
      const VerificationMeta('alertThreshold');
  @override
  late final GeneratedColumn<int> alertThreshold = GeneratedColumn<int>(
      'alert_threshold', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(80));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        category,
        limitAmount,
        currency,
        period,
        startDate,
        endDate,
        alertThreshold,
        isActive
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
          _limitAmountMeta,
          limitAmount.isAcceptableOrUnknown(
              data['limit_amount']!, _limitAmountMeta));
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('alert_threshold')) {
      context.handle(
          _alertThresholdMeta,
          alertThreshold.isAcceptableOrUnknown(
              data['alert_threshold']!, _alertThresholdMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      limitAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}limit_amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      period: $BudgetsTable.$converterperiod.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period'])!),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      alertThreshold: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}alert_threshold'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BudgetPeriod, int, int> $converterperiod =
      const EnumIndexConverter<BudgetPeriod>(BudgetPeriod.values);
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String category;
  final double limitAmount;
  final String currency;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final int alertThreshold;
  final bool isActive;
  const Budget(
      {required this.id,
      required this.category,
      required this.limitAmount,
      required this.currency,
      required this.period,
      required this.startDate,
      this.endDate,
      required this.alertThreshold,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['limit_amount'] = Variable<double>(limitAmount);
    map['currency'] = Variable<String>(currency);
    {
      map['period'] =
          Variable<int>($BudgetsTable.$converterperiod.toSql(period));
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['alert_threshold'] = Variable<int>(alertThreshold);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      category: Value(category),
      limitAmount: Value(limitAmount),
      currency: Value(currency),
      period: Value(period),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      alertThreshold: Value(alertThreshold),
      isActive: Value(isActive),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      limitAmount: serializer.fromJson<double>(json['limitAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      period: $BudgetsTable.$converterperiod
          .fromJson(serializer.fromJson<int>(json['period'])),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      alertThreshold: serializer.fromJson<int>(json['alertThreshold']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'limitAmount': serializer.toJson<double>(limitAmount),
      'currency': serializer.toJson<String>(currency),
      'period':
          serializer.toJson<int>($BudgetsTable.$converterperiod.toJson(period)),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'alertThreshold': serializer.toJson<int>(alertThreshold),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Budget copyWith(
          {String? id,
          String? category,
          double? limitAmount,
          String? currency,
          BudgetPeriod? period,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          int? alertThreshold,
          bool? isActive}) =>
      Budget(
        id: id ?? this.id,
        category: category ?? this.category,
        limitAmount: limitAmount ?? this.limitAmount,
        currency: currency ?? this.currency,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        alertThreshold: alertThreshold ?? this.alertThreshold,
        isActive: isActive ?? this.isActive,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      limitAmount:
          data.limitAmount.present ? data.limitAmount.value : this.limitAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      period: data.period.present ? data.period.value : this.period,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      alertThreshold: data.alertThreshold.present
          ? data.alertThreshold.value
          : this.alertThreshold,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('currency: $currency, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('alertThreshold: $alertThreshold, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, limitAmount, currency, period,
      startDate, endDate, alertThreshold, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.category == this.category &&
          other.limitAmount == this.limitAmount &&
          other.currency == this.currency &&
          other.period == this.period &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.alertThreshold == this.alertThreshold &&
          other.isActive == this.isActive);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> category;
  final Value<double> limitAmount;
  final Value<String> currency;
  final Value<BudgetPeriod> period;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int> alertThreshold;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.period = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.alertThreshold = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required double limitAmount,
    required String currency,
    required BudgetPeriod period,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.alertThreshold = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : category = Value(category),
        limitAmount = Value(limitAmount),
        currency = Value(currency),
        period = Value(period),
        startDate = Value(startDate);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<double>? limitAmount,
    Expression<String>? currency,
    Expression<int>? period,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? alertThreshold,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (currency != null) 'currency': currency,
      if (period != null) 'period': period,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (alertThreshold != null) 'alert_threshold': alertThreshold,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? category,
      Value<double>? limitAmount,
      Value<String>? currency,
      Value<BudgetPeriod>? period,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<int>? alertThreshold,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<double>(limitAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (period.present) {
      map['period'] =
          Variable<int>($BudgetsTable.$converterperiod.toSql(period.value));
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (alertThreshold.present) {
      map['alert_threshold'] = Variable<int>(alertThreshold.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('currency: $currency, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('alertThreshold: $alertThreshold, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _savedAmountMeta =
      const VerificationMeta('savedAmount');
  @override
  late final GeneratedColumn<double> savedAmount = GeneratedColumn<double>(
      'saved_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<GoalPriority, int> priority =
      GeneratedColumn<int>('priority', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<GoalPriority>($SavingsGoalsTable.$converterpriority);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _autoAllocateMeta =
      const VerificationMeta('autoAllocate');
  @override
  late final GeneratedColumn<bool> autoAllocate = GeneratedColumn<bool>(
      'auto_allocate', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_allocate" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        targetAmount,
        savedAmount,
        deadline,
        priority,
        color,
        autoAllocate,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(Insertable<SavingsGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('saved_amount')) {
      context.handle(
          _savedAmountMeta,
          savedAmount.isAcceptableOrUnknown(
              data['saved_amount']!, _savedAmountMeta));
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('auto_allocate')) {
      context.handle(
          _autoAllocateMeta,
          autoAllocate.isAcceptableOrUnknown(
              data['auto_allocate']!, _autoAllocateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      savedAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saved_amount'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      priority: $SavingsGoalsTable.$converterpriority.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      autoAllocate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_allocate'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalPriority, int, int> $converterpriority =
      const EnumIndexConverter<GoalPriority>(GoalPriority.values);
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final GoalPriority priority;
  final String? color;
  final bool autoAllocate;
  final DateTime createdAt;
  const SavingsGoal(
      {required this.id,
      required this.title,
      required this.targetAmount,
      required this.savedAmount,
      this.deadline,
      required this.priority,
      this.color,
      required this.autoAllocate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['target_amount'] = Variable<double>(targetAmount);
    map['saved_amount'] = Variable<double>(savedAmount);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    {
      map['priority'] =
          Variable<int>($SavingsGoalsTable.$converterpriority.toSql(priority));
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['auto_allocate'] = Variable<bool>(autoAllocate);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      title: Value(title),
      targetAmount: Value(targetAmount),
      savedAmount: Value(savedAmount),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      priority: Value(priority),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      autoAllocate: Value(autoAllocate),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      savedAmount: serializer.fromJson<double>(json['savedAmount']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      priority: $SavingsGoalsTable.$converterpriority
          .fromJson(serializer.fromJson<int>(json['priority'])),
      color: serializer.fromJson<String?>(json['color']),
      autoAllocate: serializer.fromJson<bool>(json['autoAllocate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'savedAmount': serializer.toJson<double>(savedAmount),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'priority': serializer
          .toJson<int>($SavingsGoalsTable.$converterpriority.toJson(priority)),
      'color': serializer.toJson<String?>(color),
      'autoAllocate': serializer.toJson<bool>(autoAllocate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavingsGoal copyWith(
          {String? id,
          String? title,
          double? targetAmount,
          double? savedAmount,
          Value<DateTime?> deadline = const Value.absent(),
          GoalPriority? priority,
          Value<String?> color = const Value.absent(),
          bool? autoAllocate,
          DateTime? createdAt}) =>
      SavingsGoal(
        id: id ?? this.id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline.present ? deadline.value : this.deadline,
        priority: priority ?? this.priority,
        color: color.present ? color.value : this.color,
        autoAllocate: autoAllocate ?? this.autoAllocate,
        createdAt: createdAt ?? this.createdAt,
      );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      savedAmount:
          data.savedAmount.present ? data.savedAmount.value : this.savedAmount,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      priority: data.priority.present ? data.priority.value : this.priority,
      color: data.color.present ? data.color.value : this.color,
      autoAllocate: data.autoAllocate.present
          ? data.autoAllocate.value
          : this.autoAllocate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('savedAmount: $savedAmount, ')
          ..write('deadline: $deadline, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('autoAllocate: $autoAllocate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, targetAmount, savedAmount,
      deadline, priority, color, autoAllocate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetAmount == this.targetAmount &&
          other.savedAmount == this.savedAmount &&
          other.deadline == this.deadline &&
          other.priority == this.priority &&
          other.color == this.color &&
          other.autoAllocate == this.autoAllocate &&
          other.createdAt == this.createdAt);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<String> id;
  final Value<String> title;
  final Value<double> targetAmount;
  final Value<double> savedAmount;
  final Value<DateTime?> deadline;
  final Value<GoalPriority> priority;
  final Value<String?> color;
  final Value<bool> autoAllocate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.savedAmount = const Value.absent(),
    this.deadline = const Value.absent(),
    this.priority = const Value.absent(),
    this.color = const Value.absent(),
    this.autoAllocate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double targetAmount,
    this.savedAmount = const Value.absent(),
    this.deadline = const Value.absent(),
    required GoalPriority priority,
    this.color = const Value.absent(),
    this.autoAllocate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : title = Value(title),
        targetAmount = Value(targetAmount),
        priority = Value(priority);
  static Insertable<SavingsGoal> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<double>? targetAmount,
    Expression<double>? savedAmount,
    Expression<DateTime>? deadline,
    Expression<int>? priority,
    Expression<String>? color,
    Expression<bool>? autoAllocate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (savedAmount != null) 'saved_amount': savedAmount,
      if (deadline != null) 'deadline': deadline,
      if (priority != null) 'priority': priority,
      if (color != null) 'color': color,
      if (autoAllocate != null) 'auto_allocate': autoAllocate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<double>? targetAmount,
      Value<double>? savedAmount,
      Value<DateTime?>? deadline,
      Value<GoalPriority>? priority,
      Value<String?>? color,
      Value<bool>? autoAllocate,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      autoAllocate: autoAllocate ?? this.autoAllocate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (savedAmount.present) {
      map['saved_amount'] = Variable<double>(savedAmount.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
          $SavingsGoalsTable.$converterpriority.toSql(priority.value));
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (autoAllocate.present) {
      map['auto_allocate'] = Variable<bool>(autoAllocate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('savedAmount: $savedAmount, ')
          ..write('deadline: $deadline, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('autoAllocate: $autoAllocate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<BillingCycle, int> billingCycle =
      GeneratedColumn<int>('billing_cycle', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<BillingCycle>(
              $SubscriptionsTable.$converterbillingCycle);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nextBillingDateMeta =
      const VerificationMeta('nextBillingDate');
  @override
  late final GeneratedColumn<DateTime> nextBillingDate =
      GeneratedColumn<DateTime>('next_billing_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _websiteMeta =
      const VerificationMeta('website');
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
      'website', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        amount,
        currency,
        billingCycle,
        startDate,
        nextBillingDate,
        endDate,
        category,
        isActive,
        paymentMethod,
        website,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Subscription> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('next_billing_date')) {
      context.handle(
          _nextBillingDateMeta,
          nextBillingDate.isAcceptableOrUnknown(
              data['next_billing_date']!, _nextBillingDateMeta));
    } else if (isInserting) {
      context.missing(_nextBillingDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('website')) {
      context.handle(_websiteMeta,
          website.isAcceptableOrUnknown(data['website']!, _websiteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      billingCycle: $SubscriptionsTable.$converterbillingCycle.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}billing_cycle'])!),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      nextBillingDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_billing_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      website: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}website']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BillingCycle, int, int> $converterbillingCycle =
      const EnumIndexConverter<BillingCycle>(BillingCycle.values);
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String id;
  final String name;
  final String? description;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime startDate;
  final DateTime nextBillingDate;
  final DateTime? endDate;
  final String category;
  final bool isActive;
  final String? paymentMethod;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Subscription(
      {required this.id,
      required this.name,
      this.description,
      required this.amount,
      required this.currency,
      required this.billingCycle,
      required this.startDate,
      required this.nextBillingDate,
      this.endDate,
      required this.category,
      required this.isActive,
      this.paymentMethod,
      this.website,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    {
      map['billing_cycle'] = Variable<int>(
          $SubscriptionsTable.$converterbillingCycle.toSql(billingCycle));
    }
    map['start_date'] = Variable<DateTime>(startDate);
    map['next_billing_date'] = Variable<DateTime>(nextBillingDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['category'] = Variable<String>(category);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      amount: Value(amount),
      currency: Value(currency),
      billingCycle: Value(billingCycle),
      startDate: Value(startDate),
      nextBillingDate: Value(nextBillingDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      category: Value(category),
      isActive: Value(isActive),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      billingCycle: $SubscriptionsTable.$converterbillingCycle
          .fromJson(serializer.fromJson<int>(json['billingCycle'])),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      nextBillingDate: serializer.fromJson<DateTime>(json['nextBillingDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      category: serializer.fromJson<String>(json['category']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      website: serializer.fromJson<String?>(json['website']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'billingCycle': serializer.toJson<int>(
          $SubscriptionsTable.$converterbillingCycle.toJson(billingCycle)),
      'startDate': serializer.toJson<DateTime>(startDate),
      'nextBillingDate': serializer.toJson<DateTime>(nextBillingDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'category': serializer.toJson<String>(category),
      'isActive': serializer.toJson<bool>(isActive),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'website': serializer.toJson<String?>(website),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Subscription copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          double? amount,
          String? currency,
          BillingCycle? billingCycle,
          DateTime? startDate,
          DateTime? nextBillingDate,
          Value<DateTime?> endDate = const Value.absent(),
          String? category,
          bool? isActive,
          Value<String?> paymentMethod = const Value.absent(),
          Value<String?> website = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Subscription(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        billingCycle: billingCycle ?? this.billingCycle,
        startDate: startDate ?? this.startDate,
        nextBillingDate: nextBillingDate ?? this.nextBillingDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        category: category ?? this.category,
        isActive: isActive ?? this.isActive,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        website: website.present ? website.value : this.website,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      nextBillingDate: data.nextBillingDate.present
          ? data.nextBillingDate.value
          : this.nextBillingDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      category: data.category.present ? data.category.value : this.category,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      website: data.website.present ? data.website.value : this.website,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('startDate: $startDate, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('endDate: $endDate, ')
          ..write('category: $category, ')
          ..write('isActive: $isActive, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('website: $website, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      amount,
      currency,
      billingCycle,
      startDate,
      nextBillingDate,
      endDate,
      category,
      isActive,
      paymentMethod,
      website,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.billingCycle == this.billingCycle &&
          other.startDate == this.startDate &&
          other.nextBillingDate == this.nextBillingDate &&
          other.endDate == this.endDate &&
          other.category == this.category &&
          other.isActive == this.isActive &&
          other.paymentMethod == this.paymentMethod &&
          other.website == this.website &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> amount;
  final Value<String> currency;
  final Value<BillingCycle> billingCycle;
  final Value<DateTime> startDate;
  final Value<DateTime> nextBillingDate;
  final Value<DateTime?> endDate;
  final Value<String> category;
  final Value<bool> isActive;
  final Value<String?> paymentMethod;
  final Value<String?> website;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.startDate = const Value.absent(),
    this.nextBillingDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.category = const Value.absent(),
    this.isActive = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.website = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime startDate,
    required DateTime nextBillingDate,
    this.endDate = const Value.absent(),
    required String category,
    this.isActive = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.website = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        amount = Value(amount),
        currency = Value(currency),
        billingCycle = Value(billingCycle),
        startDate = Value(startDate),
        nextBillingDate = Value(nextBillingDate),
        category = Value(category);
  static Insertable<Subscription> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<int>? billingCycle,
    Expression<DateTime>? startDate,
    Expression<DateTime>? nextBillingDate,
    Expression<DateTime>? endDate,
    Expression<String>? category,
    Expression<bool>? isActive,
    Expression<String>? paymentMethod,
    Expression<String>? website,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (startDate != null) 'start_date': startDate,
      if (nextBillingDate != null) 'next_billing_date': nextBillingDate,
      if (endDate != null) 'end_date': endDate,
      if (category != null) 'category': category,
      if (isActive != null) 'is_active': isActive,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (website != null) 'website': website,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<double>? amount,
      Value<String>? currency,
      Value<BillingCycle>? billingCycle,
      Value<DateTime>? startDate,
      Value<DateTime>? nextBillingDate,
      Value<DateTime?>? endDate,
      Value<String>? category,
      Value<bool>? isActive,
      Value<String?>? paymentMethod,
      Value<String?>? website,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<int>(
          $SubscriptionsTable.$converterbillingCycle.toSql(billingCycle.value));
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (nextBillingDate.present) {
      map['next_billing_date'] = Variable<DateTime>(nextBillingDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('startDate: $startDate, ')
          ..write('nextBillingDate: $nextBillingDate, ')
          ..write('endDate: $endDate, ')
          ..write('category: $category, ')
          ..write('isActive: $isActive, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('website: $website, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _deviceNameMeta =
      const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
      'device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _osVersionMeta =
      const VerificationMeta('osVersion');
  @override
  late final GeneratedColumn<String> osVersion = GeneratedColumn<String>(
      'os_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appVersionMeta =
      const VerificationMeta('appVersion');
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
      'app_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isTrustedMeta =
      const VerificationMeta('isTrusted');
  @override
  late final GeneratedColumn<bool> isTrusted = GeneratedColumn<bool>(
      'is_trusted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_trusted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastAuthAtMeta =
      const VerificationMeta('lastAuthAt');
  @override
  late final GeneratedColumn<DateTime> lastAuthAt = GeneratedColumn<DateTime>(
      'last_auth_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _registeredAtMeta =
      const VerificationMeta('registeredAt');
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
      'registered_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceName,
        deviceId,
        platform,
        osVersion,
        appVersion,
        isTrusted,
        isActive,
        lastAuthAt,
        registeredAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<Device> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_name')) {
      context.handle(
          _deviceNameMeta,
          deviceName.isAcceptableOrUnknown(
              data['device_name']!, _deviceNameMeta));
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('os_version')) {
      context.handle(_osVersionMeta,
          osVersion.isAcceptableOrUnknown(data['os_version']!, _osVersionMeta));
    } else if (isInserting) {
      context.missing(_osVersionMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
          _appVersionMeta,
          appVersion.isAcceptableOrUnknown(
              data['app_version']!, _appVersionMeta));
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('is_trusted')) {
      context.handle(_isTrustedMeta,
          isTrusted.isAcceptableOrUnknown(data['is_trusted']!, _isTrustedMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('last_auth_at')) {
      context.handle(
          _lastAuthAtMeta,
          lastAuthAt.isAcceptableOrUnknown(
              data['last_auth_at']!, _lastAuthAtMeta));
    } else if (isInserting) {
      context.missing(_lastAuthAtMeta);
    }
    if (data.containsKey('registered_at')) {
      context.handle(
          _registeredAtMeta,
          registeredAt.isAcceptableOrUnknown(
              data['registered_at']!, _registeredAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_name'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      osVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}os_version'])!,
      appVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_version'])!,
      isTrusted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_trusted'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      lastAuthAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_auth_at'])!,
      registeredAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}registered_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String deviceName;
  final String deviceId;
  final String platform;
  final String osVersion;
  final String appVersion;
  final bool isTrusted;
  final bool isActive;
  final DateTime lastAuthAt;
  final DateTime registeredAt;
  final DateTime updatedAt;
  const Device(
      {required this.id,
      required this.deviceName,
      required this.deviceId,
      required this.platform,
      required this.osVersion,
      required this.appVersion,
      required this.isTrusted,
      required this.isActive,
      required this.lastAuthAt,
      required this.registeredAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_name'] = Variable<String>(deviceName);
    map['device_id'] = Variable<String>(deviceId);
    map['platform'] = Variable<String>(platform);
    map['os_version'] = Variable<String>(osVersion);
    map['app_version'] = Variable<String>(appVersion);
    map['is_trusted'] = Variable<bool>(isTrusted);
    map['is_active'] = Variable<bool>(isActive);
    map['last_auth_at'] = Variable<DateTime>(lastAuthAt);
    map['registered_at'] = Variable<DateTime>(registeredAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      deviceName: Value(deviceName),
      deviceId: Value(deviceId),
      platform: Value(platform),
      osVersion: Value(osVersion),
      appVersion: Value(appVersion),
      isTrusted: Value(isTrusted),
      isActive: Value(isActive),
      lastAuthAt: Value(lastAuthAt),
      registeredAt: Value(registeredAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Device.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      platform: serializer.fromJson<String>(json['platform']),
      osVersion: serializer.fromJson<String>(json['osVersion']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      isTrusted: serializer.fromJson<bool>(json['isTrusted']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastAuthAt: serializer.fromJson<DateTime>(json['lastAuthAt']),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceName': serializer.toJson<String>(deviceName),
      'deviceId': serializer.toJson<String>(deviceId),
      'platform': serializer.toJson<String>(platform),
      'osVersion': serializer.toJson<String>(osVersion),
      'appVersion': serializer.toJson<String>(appVersion),
      'isTrusted': serializer.toJson<bool>(isTrusted),
      'isActive': serializer.toJson<bool>(isActive),
      'lastAuthAt': serializer.toJson<DateTime>(lastAuthAt),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Device copyWith(
          {String? id,
          String? deviceName,
          String? deviceId,
          String? platform,
          String? osVersion,
          String? appVersion,
          bool? isTrusted,
          bool? isActive,
          DateTime? lastAuthAt,
          DateTime? registeredAt,
          DateTime? updatedAt}) =>
      Device(
        id: id ?? this.id,
        deviceName: deviceName ?? this.deviceName,
        deviceId: deviceId ?? this.deviceId,
        platform: platform ?? this.platform,
        osVersion: osVersion ?? this.osVersion,
        appVersion: appVersion ?? this.appVersion,
        isTrusted: isTrusted ?? this.isTrusted,
        isActive: isActive ?? this.isActive,
        lastAuthAt: lastAuthAt ?? this.lastAuthAt,
        registeredAt: registeredAt ?? this.registeredAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      deviceName:
          data.deviceName.present ? data.deviceName.value : this.deviceName,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      platform: data.platform.present ? data.platform.value : this.platform,
      osVersion: data.osVersion.present ? data.osVersion.value : this.osVersion,
      appVersion:
          data.appVersion.present ? data.appVersion.value : this.appVersion,
      isTrusted: data.isTrusted.present ? data.isTrusted.value : this.isTrusted,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastAuthAt:
          data.lastAuthAt.present ? data.lastAuthAt.value : this.lastAuthAt,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('deviceName: $deviceName, ')
          ..write('deviceId: $deviceId, ')
          ..write('platform: $platform, ')
          ..write('osVersion: $osVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('isActive: $isActive, ')
          ..write('lastAuthAt: $lastAuthAt, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceName, deviceId, platform, osVersion,
      appVersion, isTrusted, isActive, lastAuthAt, registeredAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.deviceName == this.deviceName &&
          other.deviceId == this.deviceId &&
          other.platform == this.platform &&
          other.osVersion == this.osVersion &&
          other.appVersion == this.appVersion &&
          other.isTrusted == this.isTrusted &&
          other.isActive == this.isActive &&
          other.lastAuthAt == this.lastAuthAt &&
          other.registeredAt == this.registeredAt &&
          other.updatedAt == this.updatedAt);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> deviceName;
  final Value<String> deviceId;
  final Value<String> platform;
  final Value<String> osVersion;
  final Value<String> appVersion;
  final Value<bool> isTrusted;
  final Value<bool> isActive;
  final Value<DateTime> lastAuthAt;
  final Value<DateTime> registeredAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.platform = const Value.absent(),
    this.osVersion = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastAuthAt = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required String deviceName,
    required String deviceId,
    required String platform,
    required String osVersion,
    required String appVersion,
    this.isTrusted = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime lastAuthAt,
    this.registeredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceName = Value(deviceName),
        deviceId = Value(deviceId),
        platform = Value(platform),
        osVersion = Value(osVersion),
        appVersion = Value(appVersion),
        lastAuthAt = Value(lastAuthAt);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? deviceName,
    Expression<String>? deviceId,
    Expression<String>? platform,
    Expression<String>? osVersion,
    Expression<String>? appVersion,
    Expression<bool>? isTrusted,
    Expression<bool>? isActive,
    Expression<DateTime>? lastAuthAt,
    Expression<DateTime>? registeredAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceName != null) 'device_name': deviceName,
      if (deviceId != null) 'device_id': deviceId,
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'os_version': osVersion,
      if (appVersion != null) 'app_version': appVersion,
      if (isTrusted != null) 'is_trusted': isTrusted,
      if (isActive != null) 'is_active': isActive,
      if (lastAuthAt != null) 'last_auth_at': lastAuthAt,
      if (registeredAt != null) 'registered_at': registeredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? deviceName,
      Value<String>? deviceId,
      Value<String>? platform,
      Value<String>? osVersion,
      Value<String>? appVersion,
      Value<bool>? isTrusted,
      Value<bool>? isActive,
      Value<DateTime>? lastAuthAt,
      Value<DateTime>? registeredAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      isTrusted: isTrusted ?? this.isTrusted,
      isActive: isActive ?? this.isActive,
      lastAuthAt: lastAuthAt ?? this.lastAuthAt,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (osVersion.present) {
      map['os_version'] = Variable<String>(osVersion.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (isTrusted.present) {
      map['is_trusted'] = Variable<bool>(isTrusted.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastAuthAt.present) {
      map['last_auth_at'] = Variable<DateTime>(lastAuthAt.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<DateTime>(registeredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('deviceName: $deviceName, ')
          ..write('deviceId: $deviceId, ')
          ..write('platform: $platform, ')
          ..write('osVersion: $osVersion, ')
          ..write('appVersion: $appVersion, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('isActive: $isActive, ')
          ..write('lastAuthAt: $lastAuthAt, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthLogsTable extends AuthLogs with TableInfo<$AuthLogsTable, AuthLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AuthLogType, int> authType =
      GeneratedColumn<int>('auth_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AuthLogType>($AuthLogsTable.$converterauthType);
  @override
  late final GeneratedColumnWithTypeConverter<AuthStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AuthStatus>($AuthLogsTable.$converterstatus);
  static const VerificationMeta _ipAddressMeta =
      const VerificationMeta('ipAddress');
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
      'ip_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAgentMeta =
      const VerificationMeta('userAgent');
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
      'user_agent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _failedAttemptsMeta =
      const VerificationMeta('failedAttempts');
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
      'failed_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        authType,
        status,
        ipAddress,
        userAgent,
        failedAttempts,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auth_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuthLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(_ipAddressMeta,
          ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta));
    }
    if (data.containsKey('user_agent')) {
      context.handle(_userAgentMeta,
          userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta));
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
          _failedAttemptsMeta,
          failedAttempts.isAcceptableOrUnknown(
              data['failed_attempts']!, _failedAttemptsMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {deviceId, timestamp},
      ];
  @override
  AuthLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      authType: $AuthLogsTable.$converterauthType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}auth_type'])!),
      status: $AuthLogsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      ipAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip_address']),
      userAgent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_agent']),
      failedAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}failed_attempts'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $AuthLogsTable createAlias(String alias) {
    return $AuthLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AuthLogType, int, int> $converterauthType =
      const EnumIndexConverter<AuthLogType>(AuthLogType.values);
  static JsonTypeConverter2<AuthStatus, int, int> $converterstatus =
      const EnumIndexConverter<AuthStatus>(AuthStatus.values);
}

class AuthLog extends DataClass implements Insertable<AuthLog> {
  final String id;
  final String deviceId;
  final AuthLogType authType;
  final AuthStatus status;
  final String? ipAddress;
  final String? userAgent;
  final int failedAttempts;
  final DateTime timestamp;
  const AuthLog(
      {required this.id,
      required this.deviceId,
      required this.authType,
      required this.status,
      this.ipAddress,
      this.userAgent,
      required this.failedAttempts,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    {
      map['auth_type'] =
          Variable<int>($AuthLogsTable.$converterauthType.toSql(authType));
    }
    {
      map['status'] =
          Variable<int>($AuthLogsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || ipAddress != null) {
      map['ip_address'] = Variable<String>(ipAddress);
    }
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    map['failed_attempts'] = Variable<int>(failedAttempts);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AuthLogsCompanion toCompanion(bool nullToAbsent) {
    return AuthLogsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      authType: Value(authType),
      status: Value(status),
      ipAddress: ipAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(ipAddress),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
      failedAttempts: Value(failedAttempts),
      timestamp: Value(timestamp),
    );
  }

  factory AuthLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthLog(
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      authType: $AuthLogsTable.$converterauthType
          .fromJson(serializer.fromJson<int>(json['authType'])),
      status: $AuthLogsTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      ipAddress: serializer.fromJson<String?>(json['ipAddress']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'authType': serializer
          .toJson<int>($AuthLogsTable.$converterauthType.toJson(authType)),
      'status': serializer
          .toJson<int>($AuthLogsTable.$converterstatus.toJson(status)),
      'ipAddress': serializer.toJson<String?>(ipAddress),
      'userAgent': serializer.toJson<String?>(userAgent),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AuthLog copyWith(
          {String? id,
          String? deviceId,
          AuthLogType? authType,
          AuthStatus? status,
          Value<String?> ipAddress = const Value.absent(),
          Value<String?> userAgent = const Value.absent(),
          int? failedAttempts,
          DateTime? timestamp}) =>
      AuthLog(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        authType: authType ?? this.authType,
        status: status ?? this.status,
        ipAddress: ipAddress.present ? ipAddress.value : this.ipAddress,
        userAgent: userAgent.present ? userAgent.value : this.userAgent,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        timestamp: timestamp ?? this.timestamp,
      );
  AuthLog copyWithCompanion(AuthLogsCompanion data) {
    return AuthLog(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      authType: data.authType.present ? data.authType.value : this.authType,
      status: data.status.present ? data.status.value : this.status,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthLog(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('authType: $authType, ')
          ..write('status: $status, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('userAgent: $userAgent, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deviceId, authType, status, ipAddress,
      userAgent, failedAttempts, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthLog &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.authType == this.authType &&
          other.status == this.status &&
          other.ipAddress == this.ipAddress &&
          other.userAgent == this.userAgent &&
          other.failedAttempts == this.failedAttempts &&
          other.timestamp == this.timestamp);
}

class AuthLogsCompanion extends UpdateCompanion<AuthLog> {
  final Value<String> id;
  final Value<String> deviceId;
  final Value<AuthLogType> authType;
  final Value<AuthStatus> status;
  final Value<String?> ipAddress;
  final Value<String?> userAgent;
  final Value<int> failedAttempts;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const AuthLogsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.authType = const Value.absent(),
    this.status = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthLogsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required AuthLogType authType,
    required AuthStatus status,
    this.ipAddress = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        authType = Value(authType),
        status = Value(status);
  static Insertable<AuthLog> custom({
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<int>? authType,
    Expression<int>? status,
    Expression<String>? ipAddress,
    Expression<String>? userAgent,
    Expression<int>? failedAttempts,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (authType != null) 'auth_type': authType,
      if (status != null) 'status': status,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? deviceId,
      Value<AuthLogType>? authType,
      Value<AuthStatus>? status,
      Value<String?>? ipAddress,
      Value<String?>? userAgent,
      Value<int>? failedAttempts,
      Value<DateTime>? timestamp,
      Value<int>? rowid}) {
    return AuthLogsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      authType: authType ?? this.authType,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (authType.present) {
      map['auth_type'] = Variable<int>(
          $AuthLogsTable.$converterauthType.toSql(authType.value));
    }
    if (status.present) {
      map['status'] =
          Variable<int>($AuthLogsTable.$converterstatus.toSql(status.value));
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthLogsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('authType: $authType, ')
          ..write('status: $status, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('userAgent: $userAgent, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecuritySettingsTable extends SecuritySettings
    with TableInfo<$SecuritySettingsTable, SecuritySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecuritySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _generateUuid());
  static const VerificationMeta _sessionTimeoutMeta =
      const VerificationMeta('sessionTimeout');
  @override
  late final GeneratedColumn<int> sessionTimeout = GeneratedColumn<int>(
      'session_timeout', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(300));
  static const VerificationMeta _biometricEnabledMeta =
      const VerificationMeta('biometricEnabled');
  @override
  late final GeneratedColumn<bool> biometricEnabled = GeneratedColumn<bool>(
      'biometric_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("biometric_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _pinEnabledMeta =
      const VerificationMeta('pinEnabled');
  @override
  late final GeneratedColumn<bool> pinEnabled = GeneratedColumn<bool>(
      'pin_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pin_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _maxFailedAttemptsMeta =
      const VerificationMeta('maxFailedAttempts');
  @override
  late final GeneratedColumn<int> maxFailedAttempts = GeneratedColumn<int>(
      'max_failed_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _lockoutDurationMeta =
      const VerificationMeta('lockoutDuration');
  @override
  late final GeneratedColumn<int> lockoutDuration = GeneratedColumn<int>(
      'lockout_duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(900));
  static const VerificationMeta _lastSecurityUpdateMeta =
      const VerificationMeta('lastSecurityUpdate');
  @override
  late final GeneratedColumn<DateTime> lastSecurityUpdate =
      GeneratedColumn<DateTime>('last_security_update', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionTimeout,
        biometricEnabled,
        pinEnabled,
        maxFailedAttempts,
        lockoutDuration,
        lastSecurityUpdate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'security_settings';
  @override
  VerificationContext validateIntegrity(Insertable<SecuritySetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_timeout')) {
      context.handle(
          _sessionTimeoutMeta,
          sessionTimeout.isAcceptableOrUnknown(
              data['session_timeout']!, _sessionTimeoutMeta));
    }
    if (data.containsKey('biometric_enabled')) {
      context.handle(
          _biometricEnabledMeta,
          biometricEnabled.isAcceptableOrUnknown(
              data['biometric_enabled']!, _biometricEnabledMeta));
    }
    if (data.containsKey('pin_enabled')) {
      context.handle(
          _pinEnabledMeta,
          pinEnabled.isAcceptableOrUnknown(
              data['pin_enabled']!, _pinEnabledMeta));
    }
    if (data.containsKey('max_failed_attempts')) {
      context.handle(
          _maxFailedAttemptsMeta,
          maxFailedAttempts.isAcceptableOrUnknown(
              data['max_failed_attempts']!, _maxFailedAttemptsMeta));
    }
    if (data.containsKey('lockout_duration')) {
      context.handle(
          _lockoutDurationMeta,
          lockoutDuration.isAcceptableOrUnknown(
              data['lockout_duration']!, _lockoutDurationMeta));
    }
    if (data.containsKey('last_security_update')) {
      context.handle(
          _lastSecurityUpdateMeta,
          lastSecurityUpdate.isAcceptableOrUnknown(
              data['last_security_update']!, _lastSecurityUpdateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecuritySetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecuritySetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionTimeout: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_timeout'])!,
      biometricEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}biometric_enabled'])!,
      pinEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pin_enabled'])!,
      maxFailedAttempts: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_failed_attempts'])!,
      lockoutDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lockout_duration'])!,
      lastSecurityUpdate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_security_update'])!,
    );
  }

  @override
  $SecuritySettingsTable createAlias(String alias) {
    return $SecuritySettingsTable(attachedDatabase, alias);
  }
}

class SecuritySetting extends DataClass implements Insertable<SecuritySetting> {
  final String id;
  final int sessionTimeout;
  final bool biometricEnabled;
  final bool pinEnabled;
  final int maxFailedAttempts;
  final int lockoutDuration;
  final DateTime lastSecurityUpdate;
  const SecuritySetting(
      {required this.id,
      required this.sessionTimeout,
      required this.biometricEnabled,
      required this.pinEnabled,
      required this.maxFailedAttempts,
      required this.lockoutDuration,
      required this.lastSecurityUpdate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_timeout'] = Variable<int>(sessionTimeout);
    map['biometric_enabled'] = Variable<bool>(biometricEnabled);
    map['pin_enabled'] = Variable<bool>(pinEnabled);
    map['max_failed_attempts'] = Variable<int>(maxFailedAttempts);
    map['lockout_duration'] = Variable<int>(lockoutDuration);
    map['last_security_update'] = Variable<DateTime>(lastSecurityUpdate);
    return map;
  }

  SecuritySettingsCompanion toCompanion(bool nullToAbsent) {
    return SecuritySettingsCompanion(
      id: Value(id),
      sessionTimeout: Value(sessionTimeout),
      biometricEnabled: Value(biometricEnabled),
      pinEnabled: Value(pinEnabled),
      maxFailedAttempts: Value(maxFailedAttempts),
      lockoutDuration: Value(lockoutDuration),
      lastSecurityUpdate: Value(lastSecurityUpdate),
    );
  }

  factory SecuritySetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecuritySetting(
      id: serializer.fromJson<String>(json['id']),
      sessionTimeout: serializer.fromJson<int>(json['sessionTimeout']),
      biometricEnabled: serializer.fromJson<bool>(json['biometricEnabled']),
      pinEnabled: serializer.fromJson<bool>(json['pinEnabled']),
      maxFailedAttempts: serializer.fromJson<int>(json['maxFailedAttempts']),
      lockoutDuration: serializer.fromJson<int>(json['lockoutDuration']),
      lastSecurityUpdate:
          serializer.fromJson<DateTime>(json['lastSecurityUpdate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionTimeout': serializer.toJson<int>(sessionTimeout),
      'biometricEnabled': serializer.toJson<bool>(biometricEnabled),
      'pinEnabled': serializer.toJson<bool>(pinEnabled),
      'maxFailedAttempts': serializer.toJson<int>(maxFailedAttempts),
      'lockoutDuration': serializer.toJson<int>(lockoutDuration),
      'lastSecurityUpdate': serializer.toJson<DateTime>(lastSecurityUpdate),
    };
  }

  SecuritySetting copyWith(
          {String? id,
          int? sessionTimeout,
          bool? biometricEnabled,
          bool? pinEnabled,
          int? maxFailedAttempts,
          int? lockoutDuration,
          DateTime? lastSecurityUpdate}) =>
      SecuritySetting(
        id: id ?? this.id,
        sessionTimeout: sessionTimeout ?? this.sessionTimeout,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        pinEnabled: pinEnabled ?? this.pinEnabled,
        maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
        lockoutDuration: lockoutDuration ?? this.lockoutDuration,
        lastSecurityUpdate: lastSecurityUpdate ?? this.lastSecurityUpdate,
      );
  SecuritySetting copyWithCompanion(SecuritySettingsCompanion data) {
    return SecuritySetting(
      id: data.id.present ? data.id.value : this.id,
      sessionTimeout: data.sessionTimeout.present
          ? data.sessionTimeout.value
          : this.sessionTimeout,
      biometricEnabled: data.biometricEnabled.present
          ? data.biometricEnabled.value
          : this.biometricEnabled,
      pinEnabled:
          data.pinEnabled.present ? data.pinEnabled.value : this.pinEnabled,
      maxFailedAttempts: data.maxFailedAttempts.present
          ? data.maxFailedAttempts.value
          : this.maxFailedAttempts,
      lockoutDuration: data.lockoutDuration.present
          ? data.lockoutDuration.value
          : this.lockoutDuration,
      lastSecurityUpdate: data.lastSecurityUpdate.present
          ? data.lastSecurityUpdate.value
          : this.lastSecurityUpdate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecuritySetting(')
          ..write('id: $id, ')
          ..write('sessionTimeout: $sessionTimeout, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('pinEnabled: $pinEnabled, ')
          ..write('maxFailedAttempts: $maxFailedAttempts, ')
          ..write('lockoutDuration: $lockoutDuration, ')
          ..write('lastSecurityUpdate: $lastSecurityUpdate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionTimeout, biometricEnabled,
      pinEnabled, maxFailedAttempts, lockoutDuration, lastSecurityUpdate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecuritySetting &&
          other.id == this.id &&
          other.sessionTimeout == this.sessionTimeout &&
          other.biometricEnabled == this.biometricEnabled &&
          other.pinEnabled == this.pinEnabled &&
          other.maxFailedAttempts == this.maxFailedAttempts &&
          other.lockoutDuration == this.lockoutDuration &&
          other.lastSecurityUpdate == this.lastSecurityUpdate);
}

class SecuritySettingsCompanion extends UpdateCompanion<SecuritySetting> {
  final Value<String> id;
  final Value<int> sessionTimeout;
  final Value<bool> biometricEnabled;
  final Value<bool> pinEnabled;
  final Value<int> maxFailedAttempts;
  final Value<int> lockoutDuration;
  final Value<DateTime> lastSecurityUpdate;
  final Value<int> rowid;
  const SecuritySettingsCompanion({
    this.id = const Value.absent(),
    this.sessionTimeout = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.pinEnabled = const Value.absent(),
    this.maxFailedAttempts = const Value.absent(),
    this.lockoutDuration = const Value.absent(),
    this.lastSecurityUpdate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecuritySettingsCompanion.insert({
    this.id = const Value.absent(),
    this.sessionTimeout = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.pinEnabled = const Value.absent(),
    this.maxFailedAttempts = const Value.absent(),
    this.lockoutDuration = const Value.absent(),
    this.lastSecurityUpdate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<SecuritySetting> custom({
    Expression<String>? id,
    Expression<int>? sessionTimeout,
    Expression<bool>? biometricEnabled,
    Expression<bool>? pinEnabled,
    Expression<int>? maxFailedAttempts,
    Expression<int>? lockoutDuration,
    Expression<DateTime>? lastSecurityUpdate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionTimeout != null) 'session_timeout': sessionTimeout,
      if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      if (pinEnabled != null) 'pin_enabled': pinEnabled,
      if (maxFailedAttempts != null) 'max_failed_attempts': maxFailedAttempts,
      if (lockoutDuration != null) 'lockout_duration': lockoutDuration,
      if (lastSecurityUpdate != null)
        'last_security_update': lastSecurityUpdate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecuritySettingsCompanion copyWith(
      {Value<String>? id,
      Value<int>? sessionTimeout,
      Value<bool>? biometricEnabled,
      Value<bool>? pinEnabled,
      Value<int>? maxFailedAttempts,
      Value<int>? lockoutDuration,
      Value<DateTime>? lastSecurityUpdate,
      Value<int>? rowid}) {
    return SecuritySettingsCompanion(
      id: id ?? this.id,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
      lastSecurityUpdate: lastSecurityUpdate ?? this.lastSecurityUpdate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionTimeout.present) {
      map['session_timeout'] = Variable<int>(sessionTimeout.value);
    }
    if (biometricEnabled.present) {
      map['biometric_enabled'] = Variable<bool>(biometricEnabled.value);
    }
    if (pinEnabled.present) {
      map['pin_enabled'] = Variable<bool>(pinEnabled.value);
    }
    if (maxFailedAttempts.present) {
      map['max_failed_attempts'] = Variable<int>(maxFailedAttempts.value);
    }
    if (lockoutDuration.present) {
      map['lockout_duration'] = Variable<int>(lockoutDuration.value);
    }
    if (lastSecurityUpdate.present) {
      map['last_security_update'] =
          Variable<DateTime>(lastSecurityUpdate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecuritySettingsCompanion(')
          ..write('id: $id, ')
          ..write('sessionTimeout: $sessionTimeout, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('pinEnabled: $pinEnabled, ')
          ..write('maxFailedAttempts: $maxFailedAttempts, ')
          ..write('lockoutDuration: $lockoutDuration, ')
          ..write('lastSecurityUpdate: $lastSecurityUpdate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $AuthLogsTable authLogs = $AuthLogsTable(this);
  late final $SecuritySettingsTable securitySettings =
      $SecuritySettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        transactions,
        accounts,
        budgets,
        savingsGoals,
        subscriptions,
        devices,
        authLogs,
        securitySettings
      ];
}

typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  required String accountId,
  required double amount,
  required String currency,
  required TransactionType type,
  required String category,
  required DateTime date,
  Value<String?> note,
  Value<TransactionRecurrence> recurrence,
  Value<bool> isRecurring,
  Value<DateTime?> lastGeneratedAt,
  Value<DateTime?> nextDueAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> accountId,
  Value<double> amount,
  Value<String> currency,
  Value<TransactionType> type,
  Value<String> category,
  Value<DateTime> date,
  Value<String?> note,
  Value<TransactionRecurrence> recurrence,
  Value<bool> isRecurring,
  Value<DateTime?> lastGeneratedAt,
  Value<DateTime?> nextDueAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransactionRecurrence, TransactionRecurrence,
          int>
      get recurrence => $composableBuilder(
          column: $table.recurrence,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastGeneratedAt => $composableBuilder(
      column: $table.lastGeneratedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDueAt => $composableBuilder(
      column: $table.nextDueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastGeneratedAt => $composableBuilder(
      column: $table.lastGeneratedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDueAt => $composableBuilder(
      column: $table.nextDueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionRecurrence, int> get recurrence =>
      $composableBuilder(
          column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<DateTime> get lastGeneratedAt => $composableBuilder(
      column: $table.lastGeneratedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<TransactionType> type = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<TransactionRecurrence> recurrence = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<DateTime?> lastGeneratedAt = const Value.absent(),
            Value<DateTime?> nextDueAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            accountId: accountId,
            amount: amount,
            currency: currency,
            type: type,
            category: category,
            date: date,
            note: note,
            recurrence: recurrence,
            isRecurring: isRecurring,
            lastGeneratedAt: lastGeneratedAt,
            nextDueAt: nextDueAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String accountId,
            required double amount,
            required String currency,
            required TransactionType type,
            required String category,
            required DateTime date,
            Value<String?> note = const Value.absent(),
            Value<TransactionRecurrence> recurrence = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<DateTime?> lastGeneratedAt = const Value.absent(),
            Value<DateTime?> nextDueAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            accountId: accountId,
            amount: amount,
            currency: currency,
            type: type,
            category: category,
            date: date,
            note: note,
            recurrence: recurrence,
            isRecurring: isRecurring,
            lastGeneratedAt: lastGeneratedAt,
            nextDueAt: nextDueAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  required String name,
  required AccountType type,
  Value<double> balance,
  required String currency,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<AccountType> type,
  Value<double> balance,
  Value<String> currency,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountType, AccountType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<AccountType> type = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            type: type,
            balance: balance,
            currency: currency,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            required AccountType type,
            Value<double> balance = const Value.absent(),
            required String currency,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            type: type,
            balance: balance,
            currency: currency,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  required String category,
  required double limitAmount,
  required String currency,
  required BudgetPeriod period,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int> alertThreshold,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> category,
  Value<double> limitAmount,
  Value<String> currency,
  Value<BudgetPeriod> period,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int> alertThreshold,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BudgetPeriod, BudgetPeriod, int> get period =>
      $composableBuilder(
          column: $table.period,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BudgetPeriod, int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> limitAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<BudgetPeriod> period = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> alertThreshold = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            id: id,
            category: category,
            limitAmount: limitAmount,
            currency: currency,
            period: period,
            startDate: startDate,
            endDate: endDate,
            alertThreshold: alertThreshold,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String category,
            required double limitAmount,
            required String currency,
            required BudgetPeriod period,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> alertThreshold = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            id: id,
            category: category,
            limitAmount: limitAmount,
            currency: currency,
            period: period,
            startDate: startDate,
            endDate: endDate,
            alertThreshold: alertThreshold,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()>;
typedef $$SavingsGoalsTableCreateCompanionBuilder = SavingsGoalsCompanion
    Function({
  Value<String> id,
  required String title,
  required double targetAmount,
  Value<double> savedAmount,
  Value<DateTime?> deadline,
  required GoalPriority priority,
  Value<String?> color,
  Value<bool> autoAllocate,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SavingsGoalsTableUpdateCompanionBuilder = SavingsGoalsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<double> targetAmount,
  Value<double> savedAmount,
  Value<DateTime?> deadline,
  Value<GoalPriority> priority,
  Value<String?> color,
  Value<bool> autoAllocate,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GoalPriority, GoalPriority, int>
      get priority => $composableBuilder(
          column: $table.priority,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoAllocate => $composableBuilder(
      column: $table.autoAllocate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoAllocate => $composableBuilder(
      column: $table.autoAllocate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalPriority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get autoAllocate => $composableBuilder(
      column: $table.autoAllocate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavingsGoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsGoalsTable,
    SavingsGoal,
    $$SavingsGoalsTableFilterComposer,
    $$SavingsGoalsTableOrderingComposer,
    $$SavingsGoalsTableAnnotationComposer,
    $$SavingsGoalsTableCreateCompanionBuilder,
    $$SavingsGoalsTableUpdateCompanionBuilder,
    (
      SavingsGoal,
      BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal>
    ),
    SavingsGoal,
    PrefetchHooks Function()> {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> savedAmount = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            Value<GoalPriority> priority = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<bool> autoAllocate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsGoalsCompanion(
            id: id,
            title: title,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            deadline: deadline,
            priority: priority,
            color: color,
            autoAllocate: autoAllocate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String title,
            required double targetAmount,
            Value<double> savedAmount = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            required GoalPriority priority,
            Value<String?> color = const Value.absent(),
            Value<bool> autoAllocate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingsGoalsCompanion.insert(
            id: id,
            title: title,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            deadline: deadline,
            priority: priority,
            color: color,
            autoAllocate: autoAllocate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsGoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingsGoalsTable,
    SavingsGoal,
    $$SavingsGoalsTableFilterComposer,
    $$SavingsGoalsTableOrderingComposer,
    $$SavingsGoalsTableAnnotationComposer,
    $$SavingsGoalsTableCreateCompanionBuilder,
    $$SavingsGoalsTableUpdateCompanionBuilder,
    (
      SavingsGoal,
      BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal>
    ),
    SavingsGoal,
    PrefetchHooks Function()>;
typedef $$SubscriptionsTableCreateCompanionBuilder = SubscriptionsCompanion
    Function({
  Value<String> id,
  required String name,
  Value<String?> description,
  required double amount,
  required String currency,
  required BillingCycle billingCycle,
  required DateTime startDate,
  required DateTime nextBillingDate,
  Value<DateTime?> endDate,
  required String category,
  Value<bool> isActive,
  Value<String?> paymentMethod,
  Value<String?> website,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SubscriptionsTableUpdateCompanionBuilder = SubscriptionsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<double> amount,
  Value<String> currency,
  Value<BillingCycle> billingCycle,
  Value<DateTime> startDate,
  Value<DateTime> nextBillingDate,
  Value<DateTime?> endDate,
  Value<String> category,
  Value<bool> isActive,
  Value<String?> paymentMethod,
  Value<String?> website,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BillingCycle, BillingCycle, int>
      get billingCycle => $composableBuilder(
          column: $table.billingCycle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextBillingDate => $composableBuilder(
      column: $table.nextBillingDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get billingCycle => $composableBuilder(
      column: $table.billingCycle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextBillingDate => $composableBuilder(
      column: $table.nextBillingDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BillingCycle, int> get billingCycle =>
      $composableBuilder(
          column: $table.billingCycle, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get nextBillingDate => $composableBuilder(
      column: $table.nextBillingDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubscriptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubscriptionsTable,
    Subscription,
    $$SubscriptionsTableFilterComposer,
    $$SubscriptionsTableOrderingComposer,
    $$SubscriptionsTableAnnotationComposer,
    $$SubscriptionsTableCreateCompanionBuilder,
    $$SubscriptionsTableUpdateCompanionBuilder,
    (
      Subscription,
      BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>
    ),
    Subscription,
    PrefetchHooks Function()> {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<BillingCycle> billingCycle = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> nextBillingDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> website = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubscriptionsCompanion(
            id: id,
            name: name,
            description: description,
            amount: amount,
            currency: currency,
            billingCycle: billingCycle,
            startDate: startDate,
            nextBillingDate: nextBillingDate,
            endDate: endDate,
            category: category,
            isActive: isActive,
            paymentMethod: paymentMethod,
            website: website,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            required double amount,
            required String currency,
            required BillingCycle billingCycle,
            required DateTime startDate,
            required DateTime nextBillingDate,
            Value<DateTime?> endDate = const Value.absent(),
            required String category,
            Value<bool> isActive = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> website = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubscriptionsCompanion.insert(
            id: id,
            name: name,
            description: description,
            amount: amount,
            currency: currency,
            billingCycle: billingCycle,
            startDate: startDate,
            nextBillingDate: nextBillingDate,
            endDate: endDate,
            category: category,
            isActive: isActive,
            paymentMethod: paymentMethod,
            website: website,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubscriptionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubscriptionsTable,
    Subscription,
    $$SubscriptionsTableFilterComposer,
    $$SubscriptionsTableOrderingComposer,
    $$SubscriptionsTableAnnotationComposer,
    $$SubscriptionsTableCreateCompanionBuilder,
    $$SubscriptionsTableUpdateCompanionBuilder,
    (
      Subscription,
      BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>
    ),
    Subscription,
    PrefetchHooks Function()>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  required String deviceName,
  required String deviceId,
  required String platform,
  required String osVersion,
  required String appVersion,
  Value<bool> isTrusted,
  Value<bool> isActive,
  required DateTime lastAuthAt,
  Value<DateTime> registeredAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> deviceName,
  Value<String> deviceId,
  Value<String> platform,
  Value<String> osVersion,
  Value<String> appVersion,
  Value<bool> isTrusted,
  Value<bool> isActive,
  Value<DateTime> lastAuthAt,
  Value<DateTime> registeredAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get osVersion => $composableBuilder(
      column: $table.osVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTrusted => $composableBuilder(
      column: $table.isTrusted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAuthAt => $composableBuilder(
      column: $table.lastAuthAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
      column: $table.registeredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get osVersion => $composableBuilder(
      column: $table.osVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTrusted => $composableBuilder(
      column: $table.isTrusted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAuthAt => $composableBuilder(
      column: $table.lastAuthAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
      column: $table.registeredAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get osVersion =>
      $composableBuilder(column: $table.osVersion, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
      column: $table.appVersion, builder: (column) => column);

  GeneratedColumn<bool> get isTrusted =>
      $composableBuilder(column: $table.isTrusted, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAuthAt => $composableBuilder(
      column: $table.lastAuthAt, builder: (column) => column);

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
      column: $table.registeredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
    Device,
    PrefetchHooks Function()> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> deviceName = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> osVersion = const Value.absent(),
            Value<String> appVersion = const Value.absent(),
            Value<bool> isTrusted = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> lastAuthAt = const Value.absent(),
            Value<DateTime> registeredAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            deviceName: deviceName,
            deviceId: deviceId,
            platform: platform,
            osVersion: osVersion,
            appVersion: appVersion,
            isTrusted: isTrusted,
            isActive: isActive,
            lastAuthAt: lastAuthAt,
            registeredAt: registeredAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String deviceName,
            required String deviceId,
            required String platform,
            required String osVersion,
            required String appVersion,
            Value<bool> isTrusted = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime lastAuthAt,
            Value<DateTime> registeredAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            deviceName: deviceName,
            deviceId: deviceId,
            platform: platform,
            osVersion: osVersion,
            appVersion: appVersion,
            isTrusted: isTrusted,
            isActive: isActive,
            lastAuthAt: lastAuthAt,
            registeredAt: registeredAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
    Device,
    PrefetchHooks Function()>;
typedef $$AuthLogsTableCreateCompanionBuilder = AuthLogsCompanion Function({
  Value<String> id,
  required String deviceId,
  required AuthLogType authType,
  required AuthStatus status,
  Value<String?> ipAddress,
  Value<String?> userAgent,
  Value<int> failedAttempts,
  Value<DateTime> timestamp,
  Value<int> rowid,
});
typedef $$AuthLogsTableUpdateCompanionBuilder = AuthLogsCompanion Function({
  Value<String> id,
  Value<String> deviceId,
  Value<AuthLogType> authType,
  Value<AuthStatus> status,
  Value<String?> ipAddress,
  Value<String?> userAgent,
  Value<int> failedAttempts,
  Value<DateTime> timestamp,
  Value<int> rowid,
});

class $$AuthLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuthLogsTable> {
  $$AuthLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AuthLogType, AuthLogType, int> get authType =>
      $composableBuilder(
          column: $table.authType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<AuthStatus, AuthStatus, int> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$AuthLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuthLogsTable> {
  $$AuthLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get authType => $composableBuilder(
      column: $table.authType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$AuthLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuthLogsTable> {
  $$AuthLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AuthLogType, int> get authType =>
      $composableBuilder(column: $table.authType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AuthStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AuthLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuthLogsTable,
    AuthLog,
    $$AuthLogsTableFilterComposer,
    $$AuthLogsTableOrderingComposer,
    $$AuthLogsTableAnnotationComposer,
    $$AuthLogsTableCreateCompanionBuilder,
    $$AuthLogsTableUpdateCompanionBuilder,
    (AuthLog, BaseReferences<_$AppDatabase, $AuthLogsTable, AuthLog>),
    AuthLog,
    PrefetchHooks Function()> {
  $$AuthLogsTableTableManager(_$AppDatabase db, $AuthLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<AuthLogType> authType = const Value.absent(),
            Value<AuthStatus> status = const Value.absent(),
            Value<String?> ipAddress = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            Value<int> failedAttempts = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuthLogsCompanion(
            id: id,
            deviceId: deviceId,
            authType: authType,
            status: status,
            ipAddress: ipAddress,
            userAgent: userAgent,
            failedAttempts: failedAttempts,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String deviceId,
            required AuthLogType authType,
            required AuthStatus status,
            Value<String?> ipAddress = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            Value<int> failedAttempts = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuthLogsCompanion.insert(
            id: id,
            deviceId: deviceId,
            authType: authType,
            status: status,
            ipAddress: ipAddress,
            userAgent: userAgent,
            failedAttempts: failedAttempts,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuthLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuthLogsTable,
    AuthLog,
    $$AuthLogsTableFilterComposer,
    $$AuthLogsTableOrderingComposer,
    $$AuthLogsTableAnnotationComposer,
    $$AuthLogsTableCreateCompanionBuilder,
    $$AuthLogsTableUpdateCompanionBuilder,
    (AuthLog, BaseReferences<_$AppDatabase, $AuthLogsTable, AuthLog>),
    AuthLog,
    PrefetchHooks Function()>;
typedef $$SecuritySettingsTableCreateCompanionBuilder
    = SecuritySettingsCompanion Function({
  Value<String> id,
  Value<int> sessionTimeout,
  Value<bool> biometricEnabled,
  Value<bool> pinEnabled,
  Value<int> maxFailedAttempts,
  Value<int> lockoutDuration,
  Value<DateTime> lastSecurityUpdate,
  Value<int> rowid,
});
typedef $$SecuritySettingsTableUpdateCompanionBuilder
    = SecuritySettingsCompanion Function({
  Value<String> id,
  Value<int> sessionTimeout,
  Value<bool> biometricEnabled,
  Value<bool> pinEnabled,
  Value<int> maxFailedAttempts,
  Value<int> lockoutDuration,
  Value<DateTime> lastSecurityUpdate,
  Value<int> rowid,
});

class $$SecuritySettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SecuritySettingsTable> {
  $$SecuritySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sessionTimeout => $composableBuilder(
      column: $table.sessionTimeout,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get biometricEnabled => $composableBuilder(
      column: $table.biometricEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinEnabled => $composableBuilder(
      column: $table.pinEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxFailedAttempts => $composableBuilder(
      column: $table.maxFailedAttempts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lockoutDuration => $composableBuilder(
      column: $table.lockoutDuration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSecurityUpdate => $composableBuilder(
      column: $table.lastSecurityUpdate,
      builder: (column) => ColumnFilters(column));
}

class $$SecuritySettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SecuritySettingsTable> {
  $$SecuritySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sessionTimeout => $composableBuilder(
      column: $table.sessionTimeout,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get biometricEnabled => $composableBuilder(
      column: $table.biometricEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinEnabled => $composableBuilder(
      column: $table.pinEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxFailedAttempts => $composableBuilder(
      column: $table.maxFailedAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lockoutDuration => $composableBuilder(
      column: $table.lockoutDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSecurityUpdate => $composableBuilder(
      column: $table.lastSecurityUpdate,
      builder: (column) => ColumnOrderings(column));
}

class $$SecuritySettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecuritySettingsTable> {
  $$SecuritySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionTimeout => $composableBuilder(
      column: $table.sessionTimeout, builder: (column) => column);

  GeneratedColumn<bool> get biometricEnabled => $composableBuilder(
      column: $table.biometricEnabled, builder: (column) => column);

  GeneratedColumn<bool> get pinEnabled => $composableBuilder(
      column: $table.pinEnabled, builder: (column) => column);

  GeneratedColumn<int> get maxFailedAttempts => $composableBuilder(
      column: $table.maxFailedAttempts, builder: (column) => column);

  GeneratedColumn<int> get lockoutDuration => $composableBuilder(
      column: $table.lockoutDuration, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSecurityUpdate => $composableBuilder(
      column: $table.lastSecurityUpdate, builder: (column) => column);
}

class $$SecuritySettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SecuritySettingsTable,
    SecuritySetting,
    $$SecuritySettingsTableFilterComposer,
    $$SecuritySettingsTableOrderingComposer,
    $$SecuritySettingsTableAnnotationComposer,
    $$SecuritySettingsTableCreateCompanionBuilder,
    $$SecuritySettingsTableUpdateCompanionBuilder,
    (
      SecuritySetting,
      BaseReferences<_$AppDatabase, $SecuritySettingsTable, SecuritySetting>
    ),
    SecuritySetting,
    PrefetchHooks Function()> {
  $$SecuritySettingsTableTableManager(
      _$AppDatabase db, $SecuritySettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecuritySettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecuritySettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecuritySettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> sessionTimeout = const Value.absent(),
            Value<bool> biometricEnabled = const Value.absent(),
            Value<bool> pinEnabled = const Value.absent(),
            Value<int> maxFailedAttempts = const Value.absent(),
            Value<int> lockoutDuration = const Value.absent(),
            Value<DateTime> lastSecurityUpdate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SecuritySettingsCompanion(
            id: id,
            sessionTimeout: sessionTimeout,
            biometricEnabled: biometricEnabled,
            pinEnabled: pinEnabled,
            maxFailedAttempts: maxFailedAttempts,
            lockoutDuration: lockoutDuration,
            lastSecurityUpdate: lastSecurityUpdate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> sessionTimeout = const Value.absent(),
            Value<bool> biometricEnabled = const Value.absent(),
            Value<bool> pinEnabled = const Value.absent(),
            Value<int> maxFailedAttempts = const Value.absent(),
            Value<int> lockoutDuration = const Value.absent(),
            Value<DateTime> lastSecurityUpdate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SecuritySettingsCompanion.insert(
            id: id,
            sessionTimeout: sessionTimeout,
            biometricEnabled: biometricEnabled,
            pinEnabled: pinEnabled,
            maxFailedAttempts: maxFailedAttempts,
            lockoutDuration: lockoutDuration,
            lastSecurityUpdate: lastSecurityUpdate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SecuritySettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SecuritySettingsTable,
    SecuritySetting,
    $$SecuritySettingsTableFilterComposer,
    $$SecuritySettingsTableOrderingComposer,
    $$SecuritySettingsTableAnnotationComposer,
    $$SecuritySettingsTableCreateCompanionBuilder,
    $$SecuritySettingsTableUpdateCompanionBuilder,
    (
      SecuritySetting,
      BaseReferences<_$AppDatabase, $SecuritySettingsTable, SecuritySetting>
    ),
    SecuritySetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$AuthLogsTableTableManager get authLogs =>
      $$AuthLogsTableTableManager(_db, _db.authLogs);
  $$SecuritySettingsTableTableManager get securitySettings =>
      $$SecuritySettingsTableTableManager(_db, _db.securitySettings);
}
