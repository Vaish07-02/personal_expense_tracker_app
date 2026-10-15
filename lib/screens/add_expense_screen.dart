import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Education',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Other',
  ];

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final existingExpense = widget.expense;

    if (existingExpense != null) {
      _titleController.text = existingExpense.title;
      _amountController.text =
          existingExpense.amount.toString();
      _descriptionController.text =
          existingExpense.description ?? '';

      _selectedCategory = existingExpense.category;
      _selectedDate = existingExpense.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existingExpense = widget.expense;

      final expense = Expense(
        id: existingExpense?.id,
        title: _titleController.text.trim(),
        amount: double.parse(
          _amountController.text.trim(),
        ),
        category: _selectedCategory,
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (_isEditing) {
        final updatedRows =
        await DatabaseHelper.instance.updateExpense(expense);

        if (updatedRows == 0) {
          throw StateError(
            'The expense could not be found for updating.',
          );
        }
      } else {
        await DatabaseHelper.instance.insertExpense(expense);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Expense updated successfully!'
                : 'Expense added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save expense: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );

      debugPrint('Error saving expense: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Update your expense'
                      : 'Record your spending',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isEditing
                      ? 'Modify the details below.'
                      : 'Enter the details of your expense below.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                // Expense name
                TextFormField(
                  controller: _titleController,
                  textCapitalization:
                  TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Expense name',
                    hintText: 'Example: Groceries',
                    prefixIcon: Icon(
                      Icons.receipt_long_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter an expense name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Example: 250.00',
                    prefixText: '₹ ',
                    prefixIcon: Icon(
                      Icons.currency_rupee,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }

                    final amount = double.tryParse(
                      value.trim(),
                    );

                    if (amount == null ||
                        !amount.isFinite ||
                        amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Date
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expense date',
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _formatDate(_selectedDate),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Optional description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization:
                  TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add extra details...',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 28),

                // Save or update
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveExpense,
                    icon: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(
                      _isEditing
                          ? Icons.edit_outlined
                          : Icons.save_outlined,
                    ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                          ? 'Update Expense'
                          : 'Save Expense',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}