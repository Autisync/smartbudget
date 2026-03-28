import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/domain/entities/transaction.dart';
import 'package:smartbudget/data/models/tables.dart'
    show TransactionType, TransactionRecurrence;
import 'package:smartbudget/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = 'Food';
  DateTime _date = DateTime.now();
  TransactionRecurrence _recurrence = TransactionRecurrence.none;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    if (tx != null) {
      _type = tx.type;
      _category = tx.category;
      _date = tx.date;
      _recurrence = tx.recurrence;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
    }
  }

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Salary',
    'Investment',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() => _type = set.first);
                },
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _type == TransactionType.expense
                          ? Colors.redAccent
                          : Colors.greenAccent,
                    ),
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatFullDate(_date),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.edit),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Recurrence
              DropdownButtonFormField<TransactionRecurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: TransactionRecurrence.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r.name == 'none'
                                ? 'None'
                                : '${r.name[0].toUpperCase()}${r.name.substring(1)}',
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrence = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Save Button
              FilledButton(
                onPressed: _saveTransaction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.existingTransaction != null
                      ? 'Update Transaction'
                      : 'Save Transaction',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      accountId: widget.existingTransaction?.accountId ?? 'default',
      amount: amount,
      currency: 'USD',
      type: _type,
      category: _category,
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      recurrence: _recurrence,
      isSynced: widget.existingTransaction?.isSynced ?? false,
    );

    final repo = ref.read(transactionListProvider().notifier);
    if (widget.existingTransaction != null) {
      await repo.updateTransaction(transaction);
    } else {
      await repo.addTransaction(transaction);
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction saved')));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
