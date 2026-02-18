import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/widgets/toast_notification.dart';

class DebtorsScreen extends StatefulWidget {
  const DebtorsScreen({super.key});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      context.read<UserProvider>().loadUsers(),
      context.read<TransactionProvider>().loadTransactions(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendBulkReminders(List<AppUser> debtors) async {
    if (debtors.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Bulk Reminders'),
        content: Text('Are you sure you want to send reminders to all ${debtors.length} debtors for ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send All')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final notificationProvider = context.read<NotificationProvider>();
      final monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));
      
      for (var user in debtors) {
        await notificationProvider.sendNotification(
          recipientId: user.uid,
          title: 'Monthly Contribution Reminder',
          message: 'Dear ${user.fullName}, this is a gentle reminder to pay your monthly contribution for $monthName.',
          type: 'system',
        );
      }
      
      if (mounted) {
        ToastNotification.showSuccess(context, 'Reminders sent to all debtors');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(context, 'Failed to send some reminders');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.appUser;
    
    final debtorIds = transactionProvider.getDebtorsForMonth(userProvider.users, _selectedYear, _selectedMonth);
    final debtors = userProvider.users.where((u) => debtorIds.contains(u.uid)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debtors List'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                    items: List.generate(5, (index) => DateTime.now().year - index)
                        .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedYear = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                    items: List.generate(12, (index) => index + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM').format(DateTime(2022, m))),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                  ),
                ),
              ],
            ),
          ),

          // Debtor Count Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${debtors.length} Debtors Found',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (currentUser?.role == UserRole.cashier && debtors.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _sendBulkReminders(debtors),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Remind All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : debtors.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: debtors.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = debtors[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Text(user.fullName[0], style: TextStyle(color: Colors.red.shade900)),
                            ),
                            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(user.phone),
                            trailing: currentUser?.role == UserRole.cashier
                                ? IconButton(
                                    icon: const Icon(Icons.notification_add, color: AppTheme.primaryColor),
                                    onPressed: () => _sendSingleReminder(user),
                                    tooltip: 'Send Reminder',
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSingleReminder(AppUser user) async {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      final monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));
      
      await notificationProvider.sendNotification(
        recipientId: user.uid,
        title: 'Monthly Contribution Reminder',
        message: 'Dear ${user.fullName}, this is a gentle reminder to pay your monthly contribution for $monthName.',
        type: 'system',
      );
      
      if (mounted) {
        ToastNotification.showSuccess(context, 'Reminder sent to ${user.fullName}');
      }
    } catch (e) {
      if (mounted) ToastNotification.showError(context, 'Failed to send reminder');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Debtors Found!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const Text('Everyone has paid for this month.'),
        ],
      ),
    );
  }
}
