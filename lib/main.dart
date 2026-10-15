import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'models/expense.dart';
import 'screens/add_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B57),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        useMaterial3: true,
      ),
      home: const ExpenseDashboard(),
    );
  }
}

class ExpenseDashboard extends StatefulWidget {
  const ExpenseDashboard({super.key});

  @override
  State<ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<ExpenseDashboard> {
  List<Expense> _expenses = [];

  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // Load expenses from the SQLite database.
  Future<void> _loadExpenses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final expenses =
      await DatabaseHelper.instance.getAllExpenses();

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading expenses: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage =
        'Unable to load expenses. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Calculate the total expenses.
  double get _totalExpenses {
    return _expenses.fold(
      0.0,
          (total, expense) => total + expense.amount,
    );
  }

  // Calculate the total for each category.
  double _categoryTotal(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(
      0.0,
          (total, expense) => total + expense.amount,
    );
  }

  // Get the icon for each category.
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Education':
        return Icons.school;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.medical_services;
      case 'Bills':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }

  // Get the color for each category.
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Education':
        return Colors.purple;
      case 'Shopping':
        return Colors.pink;
      case 'Entertainment':
        return Colors.indigo;
      case 'Health':
        return Colors.red;
      case 'Bills':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Format amounts in Indian rupees.
  String _formatRupees(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format the expense date.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // Navigate to the Add Expense screen.
  Future<void> _addExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadExpenses();
    }
  }

  // Navigate to the Edit Expense screen.
  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expense: expense,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadExpenses();
    }
  }

  // Delete an expense after confirmation.
  Future<void> _deleteExpense(Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Are you sure you want to delete '
                '"${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    try {
      if (expense.id == null) {
        throw StateError('Expense ID is missing.');
      }

      final deletedRows =
      await DatabaseHelper.instance.deleteExpense(
        expense.id!,
      );

      if (!mounted) return;

      if (deletedRows > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadExpenses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense was not found.'),
          ),
        );

        await _loadExpenses();
      }
    } catch (error) {
      debugPrint('Error deleting expense: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete expense. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF176B57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh expenses',
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: const Color(0xFF176B57),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadExpenses,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 900;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              110,
            ),
            children: [
              const Text(
                'Hello!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your spending and manage your money.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              _buildTotalCard(),

              const SizedBox(height: 28),

              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildCategoriesSection(
                        isWideScreen: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _buildTransactionsSection(),
                    ),
                  ],
                )
              else ...[
                _buildCategoriesSection(
                  isWideScreen: false,
                ),
                const SizedBox(height: 28),
                _buildTransactionsSection(),
              ],
            ],
          );
        },
      ),
    );
  }

  // Total expense summary card.
  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF176B57),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Recorded Expenses',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatRupees(_totalExpenses),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_expenses.length} transactions recorded',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Responsive category section.
  Widget _buildCategoriesSection({
    required bool isWideScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Categories',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWideScreen ? 2 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 115,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final color = _getCategoryColor(category);
            final total = _categoryTotal(category);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatRupees(total),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Recent transactions heading and list.
  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_expenses.length} total',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRecentTransactions(),
      ],
    );
  }

  // Transactions with permanently visible Edit and Delete buttons.
  Widget _buildRecentTransactions() {
    if (_expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 45,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap Add Expense to record your first transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _expenses.map((expense) {
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                      _getCategoryColor(expense.category)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        color: _getCategoryColor(expense.category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${expense.category} • '
                                '${_formatDate(expense.date)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          if (expense.description != null &&
                              expense.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              expense.description!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRupees(expense.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF176B57),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                // Always-visible action buttons.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editExpense(expense),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteExpense(expense),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}