import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/widgets/toast_notification.dart';
import '../utils/app_theme.dart';
import '../services/report_service.dart';

class TransactionManagementWidget extends StatefulWidget {
  const TransactionManagementWidget({super.key});

  @override
  State<TransactionManagementWidget> createState() => _TransactionManagementWidgetState();
}

class _TransactionManagementWidgetState extends State<TransactionManagementWidget> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _filterType;
  TransactionCategory? _filterCategory;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(transactionProvider),
              _buildFilters(),
              _buildSearchBar(),
              filteredTransactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(filteredTransactions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TransactionProvider transactionProvider) {
    final currencyFormat = NumberFormat.currency(symbol: '₦');
    final totalCredits = transactionProvider.getTotalCredits();
    final totalDebits = transactionProvider.getTotalDebits();
    final balance = transactionProvider.getTotalFunds();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Balance',
                  currencyFormat.format(balance),
                  balance >= 0 ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatCard(
                  'Total Income',
                  currencyFormat.format(totalCredits),
                  Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatCard(
                  'Total Expenses',
                  currencyFormat.format(totalDebits),
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TransactionType?>(
                          value: _filterType,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<TransactionType?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...TransactionType.values.map((type) {
                              return DropdownMenuItem<TransactionType?>(
                                value: type,
                                child: Text(type.value.toUpperCase()),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterType = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TransactionCategory?>(
                          value: _filterCategory,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<TransactionCategory?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...TransactionCategory.values.map((category) {
                              return DropdownMenuItem<TransactionCategory?>(
                                value: category,
                                child: Text(category.value),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _dateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
                  ),
                ),
              ),

              if (_dateRange != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                ),
            ],
          ),

          const SizedBox(height: 8),

          if (_filterType != null || _filterCategory != null || _dateRange != null)
            Center(
              child: TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All Filters'),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Export Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportReport(isPdf: true),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportReport(isPdf: false),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search transactions by category, description, or amount...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<FinancialTransaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '₦');
    final isCredit = transaction.type == TransactionType.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.add_circle : Icons.remove_circle,
              color: isCredit ? Colors.green : Colors.red,
              size: 24,
            ),
          ),

          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.category.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              Text(
                '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Row(
                children: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.getUserById(transaction.linkedUser);
                      return Expanded(
                        child: Text(
                          'User: ${user?.fullName ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      transaction.type.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                DateFormat('MMMM dd, yyyy • hh:mm a').format(transaction.date),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black38,
                ),
              ),

              if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                const SizedBox(height: 4),

                Text(
                  transaction.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (transaction.coveredMonths != null && transaction.coveredMonths!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Covered: ${transaction.coveredMonths!.map((m) {
                    final parts = m.split('-');
                    final date = DateTime(int.parse(parts[1]), int.parse(parts[0]));
                    return DateFormat('MMM yyyy').format(date);
                  }).join(', ')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),

          trailing: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.appUser;
              final canEdit = currentUser != null &&
                  (currentUser.role == UserRole.president ||
                      (currentUser.role == UserRole.cashier &&
                          transaction.createdBy == currentUser.uid));

              if (!canEdit) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (value) => _handleTransactionAction(value, transaction),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 18),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<FinancialTransaction> _getFilteredTransactions(List<FinancialTransaction> transactions) {
    List<FinancialTransaction> filtered = List.from(transactions);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((transaction) {
        return transaction.category.value.toLowerCase().contains(query) ||
            transaction.description?.toLowerCase().contains(query) == true ||
            transaction.amount.toString().contains(query);
      }).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_filterCategory != null) {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }

    if (_dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterCategory = null;
      _dateRange = null;
    });
  }

  Future<void> _exportReport({required bool isPdf}) async {
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();
    
    final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);
    
    if (filteredTransactions.isEmpty) {
      ToastNotification.showInfo(context, 'No transactions to export');
      return;
    }

    // Create user mapping for the report
    final Map<String, String> userNames = {};
    for (var u in userProvider.users) {
      userNames[u.uid] = u.fullName;
    }

    try {
      if (isPdf) {
        await ReportService.exportTransactionsToPdf(
          transactions: filteredTransactions,
          userNames: userNames,
          title: _getReportTitle(),
        );
      } else {
        await ReportService.exportTransactionsToExcel(
          transactions: filteredTransactions,
          userNames: userNames,
          title: _getReportTitle(),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(context, 'Export failed: $e');
      }
    }
  }

  String _getReportTitle() {
    String title = 'Financial Report';
    if (_filterType != null) title += ' - ${_filterType!.value.toUpperCase()}';
    if (_filterCategory != null) title += ' - ${_filterCategory!.value}';
    if (_dateRange != null) {
      title += ' (${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} to ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)})';
    }
    return title;
  }

  void _handleTransactionAction(String action, FinancialTransaction transaction) {
    switch (action) {
      case 'edit':
        _showEditTransactionDialog(transaction);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(transaction);
        break;
      case 'details':
        _showTransactionDetailsDialog(transaction);
        break;
    }
  }

  void _showEditTransactionDialog(FinancialTransaction transaction) {
    final amountController = TextEditingController(text: transaction.amount.toString());
    final descriptionController = TextEditingController(text: transaction.description ?? '');
    TransactionCategory selectedCategory = transaction.category;
    DateTime selectedDate = transaction.date;
    List<String> selectedMonths = List.from(transaction.coveredMonths ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₦',
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<TransactionCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: _getAvailableCategoriesForType(transaction.type).map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.description),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                    ),
                    child: Text(DateFormat('MMMM dd, yyyy').format(selectedDate)),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),

                if (transaction.type == TransactionType.credit && selectedCategory == TransactionCategory.monthly) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Months Covered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            helpText: 'SELECT MONTH (Day is ignored)',
                            initialDatePickerMode: DatePickerMode.year,
                          );

                          if (picked != null) {
                            final monthKey = DateFormat('MM-yyyy').format(picked);
                            setState(() {
                              if (!selectedMonths.contains(monthKey)) {
                                selectedMonths.add(monthKey);
                                selectedMonths.sort((a, b) {
                                  final aParts = a.split('-');
                                  final bParts = b.split('-');
                                  final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
                                  final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
                                  return aDate.compareTo(bDate);
                                });
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 20, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedMonths.isEmpty
                                      ? 'Select Months'
                                      : selectedMonths.map((m) {
                                          final parts = m.split('-');
                                          final date = DateTime(int.parse(parts[1]), int.parse(parts[0]));
                                          return DateFormat('MMM yyyy').format(date);
                                        }).join(', '),
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedMonths.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setState(() => selectedMonths.clear()),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ToastNotification.showError(context, 'Please enter a valid amount');
                  return;
                }

                Navigator.pop(context);

                final updatedTransaction = transaction.copyWith(
                  amount: amount,
                  category: selectedCategory,
                  date: selectedDate,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  coveredMonths: (transaction.type == TransactionType.credit && selectedCategory == TransactionCategory.monthly)
                      ? selectedMonths
                      : null,
                );

                final success = await context
                    .read<TransactionProvider>()
                    .updateTransaction(updatedTransaction);

                if (success && mounted) {
                  ToastNotification.showSuccess(context, 'Transaction updated successfully!');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(FinancialTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${transaction.category.description} transaction of ${NumberFormat.currency(symbol: '₦').format(transaction.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await context
                  .read<TransactionProvider>()
                  .deleteTransaction(transaction.id);

              if (success && mounted) {
                ToastNotification.showSuccess(context, 'Transaction deleted successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetailsDialog(FinancialTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.category.description),
        content: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.getUserById(transaction.linkedUser);
            final creator = userProvider.getUserById(transaction.createdBy);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', transaction.type.value.toUpperCase()),
                _buildDetailRow('Category', transaction.category.description),
                _buildDetailRow(
                  'Amount',
                  NumberFormat.currency(symbol: '₦').format(transaction.amount),
                ),
                _buildDetailRow(
                  'Date',
                  DateFormat('MMMM dd, yyyy • hh:mm a').format(transaction.date),
                ),
                _buildDetailRow('Linked User', user?.fullName ?? 'Unknown'),
                _buildDetailRow('Created By', creator?.fullName ?? 'Unknown'),
                if (transaction.description != null && transaction.description!.isNotEmpty)
                  _buildDetailRow('Description', transaction.description!),
                if (transaction.coveredMonths != null && transaction.coveredMonths!.isNotEmpty)
                  _buildDetailRow(
                    'Months Covered',
                    transaction.coveredMonths!.map((m) {
                      final parts = m.split('-');
                      final date = DateTime(int.parse(parts[1]), int.parse(parts[0]));
                      return DateFormat('MMM yyyy').format(date);
                    }).join(', '),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionCategory> _getAvailableCategoriesForType(TransactionType type) {
    if (type == TransactionType.credit) {
      return [TransactionCategory.monthly, TransactionCategory.donation];
    } else {
      return [
        TransactionCategory.marayu,
        TransactionCategory.taimako,
        TransactionCategory.maralafiya,
      ];
    }
  }
}