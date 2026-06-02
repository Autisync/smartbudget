import 'package:flutter/material.dart';
import 'package:smartbudget/components/forms/currency_input.dart';
import 'package:smartbudget/components/forms/financial_input.dart';
import 'package:smartbudget/components/forms/form_section.dart';
import 'package:smartbudget/components/forms/modern_select.dart';

class FormExample extends StatefulWidget {
  const FormExample({super.key});

  @override
  State<FormExample> createState() => _FormExampleState();
}

class _FormExampleState extends State<FormExample> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Food';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSection(
          title: 'Example',
          subtitle: 'Reusable modern controls',
          children: [
            ModernInput(controller: _nameController, label: 'Name'),
            const SizedBox(height: 16),
            CurrencyInput(
              controller: _amountController,
              label: 'Amount',
              currencySymbol: r'$',
            ),
            const SizedBox(height: 16),
            ModernSelect<String>(
              value: _category,
              label: 'Category',
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
