import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../core/utils/app_theme.dart';

class UserFilters {
  UserRole? role;
  String? searchQuery;
  String? sortBy; // 'name', 'date', 'role'

  UserFilters({
    this.role,
    this.searchQuery,
    this.sortBy = 'name',
  });

  bool get hasActiveFilters =>
      role != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  void clear() {
    role = null;
    searchQuery = null;
    sortBy = 'name';
  }
}

class UserFilterSheet extends StatefulWidget {
  final UserFilters currentFilters;
  final Function(UserFilters) onApply;

  const UserFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<UserFilterSheet> createState() => _UserFilterSheetState();
}

class _UserFilterSheetState extends State<UserFilterSheet> {
  late UserFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = UserFilters(
      role: widget.currentFilters.role,
      searchQuery: widget.currentFilters.searchQuery,
      sortBy: widget.currentFilters.sortBy,
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
                'Filter Users',
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

          // User Role
          _buildSectionTitle('User Role'),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _filters.role == null,
                onSelected: () {
                  setState(() => _filters.role = null);
                },
              ),
              ...UserRole.values.map((role) {
                return _buildFilterChip(
                  label: role.value,
                  selected: _filters.role == role,
                  onSelected: () {
                    setState(() => _filters.role = role);
                  },
                );
              }).toList(),
            ],
          ),

          const SizedBox(height: 16),

          // Sort By
          _buildSectionTitle('Sort By'),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'Name',
                selected: _filters.sortBy == 'name',
                onSelected: () {
                  setState(() => _filters.sortBy = 'name');
                },
              ),
              _buildFilterChip(
                label: 'Date Joined',
                selected: _filters.sortBy == 'date',
                onSelected: () {
                  setState(() => _filters.sortBy = 'date');
                },
              ),
              _buildFilterChip(
                label: 'Role',
                selected: _filters.sortBy == 'role',
                onSelected: () {
                  setState(() => _filters.sortBy = 'role');
                },
              ),
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
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

// Helper function to filter users
List<AppUser> filterUsers(
  List<AppUser> users,
  UserFilters filters,
) {
  var filtered = users;

  // Filter by search query
  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    filtered = filtered.where((u) {
      return u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          (u.phone?.contains(query) ?? false);
    }).toList();
  }

  // Filter by role
  if (filters.role != null) {
    filtered = filtered.where((u) => u.role == filters.role).toList();
  }

  // Sort
  if (filters.sortBy == 'name') {
    filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
  } else if (filters.sortBy == 'date') {
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  } else if (filters.sortBy == 'role') {
    filtered.sort((a, b) => a.role.index.compareTo(b.role.index));
  }

  return filtered;
}
