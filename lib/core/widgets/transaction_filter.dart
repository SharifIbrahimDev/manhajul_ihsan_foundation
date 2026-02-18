import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../core/utils/app_theme.dart';

class TransactionFilters {
  DateTimeRange? dateRange;
  TransactionType? type;
  TransactionCategory? category;
  String? searchQuery;

  TransactionFilters({
    this.dateRange,
    this.type,
    this.category,
    this.searchQuery,
  });

  bool get hasActiveFilters =>
      dateRange != null ||
      type != null ||
      category != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  void clear() {
    dateRange = null;
    type = null;
    category = null;
    searchQuery = null;
  }
}

class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilters currentFilters;
  final Function(TransactionFilters) onApply;

  const TransactionFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = TransactionFilters(
      dateRange: widget.currentFilters.dateRange,
      type: widget.currentFilters.type,
      category: widget.currentFilters.category,
      searchQuery: widget.currentFilters.searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date Range
          _buildSectionTitle('Date Range'),
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _filters.dateRange != null
                          ? '${DateFormat('MMM dd, yyyy').format(_filters.dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_filters.dateRange!.end)}'
                          : 'Select date range',
                      style: TextStyle(
                        color: _filters.dateRange != null
                            ? null
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (_filters.dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() => _filters.dateRange = null);
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Transaction Type
          _buildSectionTitle('Transaction Type'),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _filters.type == null,
                onSelected: () {
                  setState(() => _filters.type = null);
                },
              ),
              _buildFilterChip(
                label: 'Income',
                selected: _filters.type == TransactionType.credit,
                onSelected: () {
                  setState(() => _filters.type = TransactionType.credit);
                },
                color: Colors.green,
              ),
              _buildFilterChip(
                label: 'Expense',
                selected: _filters.type == TransactionType.debit,
                onSelected: () {
                  setState(() => _filters.type = TransactionType.debit);
                },
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Category
          _buildSectionTitle('Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _filters.category == null,
                onSelected: () {
                  setState(() => _filters.category = null);
                },
              ),
              ...TransactionCategory.values.map((cat) {
                return _buildFilterChip(
                  label: cat.value,
                  selected: _filters.category == cat,
                  onSelected: () {
                    setState(() => _filters.category = cat);
                  },
                );
              }).toList(),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _filters.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: (color ?? AppTheme.primaryColor).withValues(alpha: 0.2),
      checkmarkColor: color ?? AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: selected ? (color ?? AppTheme.primaryColor) : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _filters.dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _filters.dateRange = picked);
    }
  }
}

// Helper function to filter transactions
List<FinancialTransaction> filterTransactions(
  List<FinancialTransaction> transactions,
  TransactionFilters filters,
) {
  var filtered = transactions;

  // Filter by search query
  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    filtered = filtered.where((t) {
      return t.category.description.toLowerCase().contains(query) ||
          (t.description?.toLowerCase().contains(query) ?? false) ||
          t.amount.toString().contains(query);
    }).toList();
  }

  // Filter by date range
  if (filters.dateRange != null) {
    filtered = filtered.where((t) {
      return t.date.isAfter(filters.dateRange!.start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(filters.dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Filter by type
  if (filters.type != null) {
    filtered = filtered.where((t) => t.type == filters.type).toList();
  }

  // Filter by category
  if (filters.category != null) {
    filtered = filtered.where((t) => t.category == filters.category).toList();
  }

  return filtered;
}
