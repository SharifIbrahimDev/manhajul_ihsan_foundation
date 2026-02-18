import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../utils/app_theme.dart';

import '../../core/widgets/user_filter.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/toast_notification.dart';

class UserManagementWidget extends StatefulWidget {
  const UserManagementWidget({super.key});

  @override
  State<UserManagementWidget> createState() => _UserManagementWidgetState();
}

class _UserManagementWidgetState extends State<UserManagementWidget> {
  UserFilters _filters = UserFilters();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserFilterSheet(
        currentFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
          _searchController.text = filters.searchQuery ?? '';
          
          ToastNotification.showInfo(
            context, 
            'User filters applied'
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Apply filters
        _filters.searchQuery = _searchController.text;
        final filteredUsers = filterUsers(userProvider.users, _filters);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(userProvider),
              
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: 'Search users...',
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _filters.searchQuery = value;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _filters.searchQuery = '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _filters.hasActiveFilters 
                            ? AppTheme.primaryColor 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: _filters.hasActiveFilters 
                              ? Colors.white 
                              : AppTheme.primaryColor,
                        ),
                        onPressed: _openFilterSheet,
                        tooltip: 'Filter Users',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUserList(filteredUsers, authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserProvider userProvider) {
    final roleStats = userProvider.getRoleStatistics();

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
            'User Statistics',
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
                  'Presidents',
                  roleStats[UserRole.president]?.toString() ?? '0',
                  Colors.purple,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatCard(
                  'Registrars',
                  roleStats[UserRole.registrar]?.toString() ?? '0',
                  Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatCard(
                  'Cashiers',
                  roleStats[UserRole.cashier]?.toString() ?? '0',
                  Colors.orange,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildStatCard(
                  'Users',
                  roleStats[UserRole.user]?.toString() ?? '0',
                  Colors.green,
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
              fontSize: 20,
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



  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try adjusting your search terms',
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

  Widget _buildUserList(List<AppUser> users, AuthProvider authProvider) {
    final currentUser = authProvider.appUser;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.uid == currentUser?.uid;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRoleColor(user.role).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: user.photoUrl != null
                    ? Image.network(
                        user.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialAvatar(user),
                      )
                    : _buildInitialAvatar(user),
              ),
            ),

              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  if (isCurrentUser)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        'Joined ${DateFormat('MMM yyyy').format(user.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              trailing: !isCurrentUser && currentUser?.role == UserRole.president
                  ? PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 18),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),

                  const PopupMenuItem(
                    value: 'view_details',
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 18),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                ],
              )
                  : null,
            ),
          );
        },
      );
    }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.president:
        return Colors.purple;
      case UserRole.registrar:
        return Colors.blue;
      case UserRole.cashier:
        return Colors.orange;
      case UserRole.user:
        return Colors.green;
    }
  }

  Widget _buildInitialAvatar(AppUser user) {
    return Container(
      color: _getRoleColor(user.role),
      child: Center(
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void _handleUserAction(String action, AppUser user) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(user);
        break;
      case 'view_details':
        _showUserDetailsDialog(user);
        break;
    }
  }

  void _showChangeRoleDialog(AppUser user) {
    UserRole? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role for ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(role.value),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) => setState(() => selectedRole = value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: selectedRole == user.role
                  ? null
                  : () async {
                Navigator.pop(context);

                final success = await context
                    .read<UserProvider>()
                    .updateUserRole(user.uid, selectedRole!);

                if (success && mounted) {
                  ToastNotification.showSuccess(
                    context,
                    '${user.fullName}\'s role updated to ${selectedRole!.value}',
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Phone', user.phone),
            _buildDetailRow('Address', user.address),
            _buildDetailRow('Role', user.role.value),
            _buildDetailRow(
              'Member Since',
              DateFormat('MMMM dd, yyyy').format(user.createdAt),
            ),
          ],
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
            width: 80,
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
}