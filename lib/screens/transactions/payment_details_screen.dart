import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart'; // To find cashiers
import '../../providers/notification_provider.dart';
import '../../core/widgets/toast_notification.dart';
import '../../models/app_models.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  // Bank Details
  final String _accountName = "Ibrahim Sharif Abubakar";
  final String _bankName = "Access Bank";
  final String _accountNumber = "0815267247";

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isNotifying = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ToastNotification.showSuccess(context, '$label copied to clipboard');
  }

  Future<void> _notifyCashier() async {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    if (amountText.isEmpty) {
      ToastNotification.showError(context, 'Please enter the amount paid');
      return;
    }

    setState(() => _isNotifying = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final currentUser = authProvider.appUser!;

      // Find all cashiers
      final cashiers = await userProvider.getUsersByRole(UserRole.cashier);

      if (cashiers.isEmpty) {
        if (mounted) {
           ToastNotification.showInfo(context, 'No cashier found to notify, but payment noted.');
        }
        return;
      }

      final currencyFormat = NumberFormat.currency(symbol: '₦');
      final amount = double.tryParse(amountText) ?? 0;
      final formattedAmount = currencyFormat.format(amount);
      
      final message = 'User ${currentUser.fullName} claims to have paid $formattedAmount. '
          'Note: ${_noteController.text.isNotEmpty ? _noteController.text : "No notes."}';

      // Notify each cashier
      for (var cashier in cashiers) {
        await notificationProvider.sendNotification(
          recipientId: cashier.uid,
          title: 'Payment Notification',
          message: message,
          type: 'payment_claim', // Custom type
        );
      }

      if (mounted) {
        ToastNotification.showSuccess(context, 'Cashier(s) notified successfully');
        _amountController.clear();
        _noteController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.showError(context, 'Failed to notify cashier: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isNotifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bank Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.account_balance, color: Colors.white70, size: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Bank Transfer',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Account Number',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _accountNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                        onPressed: () => _copyToClipboard(_accountNumber, 'Account number'),
                        tooltip: 'Copy Account Number',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Name',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _accountName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Bank',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bankName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Notify Cashier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'After making a payment, please notify the cashier to update your records.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Paid (₦)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g., Payment for January monthly due',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isNotifying ? null : _notifyCashier,
              icon: _isNotifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.notifications_active),
              label: Text(_isNotifying ? 'Notifying...' : 'Notify Cashier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
