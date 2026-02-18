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

class MonthlyContributionScreen extends StatefulWidget {
  const MonthlyContributionScreen({super.key});

  @override
  State<MonthlyContributionScreen> createState() => _MonthlyContributionScreenState();
}

class _MonthlyContributionScreenState extends State<MonthlyContributionScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      
      setState(() => _isLoading = true);
      await Future.wait([
        userProvider.loadUsers(),
        transactionProvider.loadTransactions(),
      ]);
      setState(() => _isLoading = false);
    });
  }

  Future<void> _sendReminder(AppUser user) async {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      
      await notificationProvider.sendNotification(
        recipientId: user.uid,
        title: 'Monthly Contribution Reminder',
        message: 'Dear ${user.fullName}, this is a gentle reminder to pay your monthly contribution for ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}.',
        type: 'system',
      );
      
      if (mounted) {
        ToastNotification.showSuccess(context, 'Reminder sent to ${user.fullName}');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(context, 'Failed to send reminder');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.appUser;
    final isStaff = currentUser?.role == UserRole.president || 
                   currentUser?.role == UserRole.cashier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Contributions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(5, (index) => DateTime.now().year - index)
                        .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12, (index) => index + 1)
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(DateFormat('MMMM').format(DateTime(2022, month))),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMonth = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (isStaff)
            Expanded(child: _buildStaffView(currentUser!))
          else
            Expanded(child: _buildUserView(currentUser!)),
        ],
      ),
    );
  }

  Widget _buildStaffView(AppUser currentUser) {
    return Consumer2<UserProvider, TransactionProvider>(
      builder: (context, userProvider, transactionProvider, child) {
        final allUsers = userProvider.users
            .where((u) => u.role == UserRole.user) // Only check regular users status
            .toList();
            
        return ListView.separated(
          itemCount: allUsers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = allUsers[index];
            final hasPaid = transactionProvider.checkMonthlyPaymentStatus(
              user.uid, 
              _selectedYear, 
              _selectedMonth
            );

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: hasPaid ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  hasPaid ? Icons.check : Icons.close,
                  color: hasPaid ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                hasPaid ? 'Paid' : 'Not Paid',
                style: TextStyle(
                  color: hasPaid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: !hasPaid && currentUser.role == UserRole.cashier
                  ? OutlinedButton.icon(
                      onPressed: () => _sendReminder(user),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Remind'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildUserView(AppUser currentUser) {
    // Show status for all months of the selected year for this user
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 12,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final month = index + 1;
            // Don't show future months
            final now = DateTime.now();
            if (_selectedYear == now.year && month > now.month) return const SizedBox.shrink();
            
            final hasPaid = transactionProvider.checkMonthlyPaymentStatus(
              currentUser.uid, 
              _selectedYear, 
              month
            );

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPaid ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: hasPaid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      hasPaid ? Icons.check_circle : Icons.warning_rounded,
                      color: hasPaid ? Colors.green : Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM').format(DateTime(_selectedYear, month)),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasPaid ? 'Contribution Paid' : 'Payment Pending',
                          style: TextStyle(
                            color: hasPaid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
