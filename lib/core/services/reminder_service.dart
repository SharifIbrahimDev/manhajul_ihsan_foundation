import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import '../../firebase_options.dart';
import '../../models/app_models.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // We only want to run this on the 1st of the month
      // Workmanager doesn't have a built-in "once a month" scheduler, 
      // so we run daily and check if it's the 1st.
      if (now.day != 1) {
        return Future.value(true);
      }

      final monthName = DateFormat('MMMM yyyy').format(now);
      
      // 1. Fetch all users
      final usersSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.user.value)
          .get();
      
      final users = usersSnapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
      
      // 2. Fetch all transactions for this month and previous months
      // In a real app, we'd check against a more complex debtor logic
      // For now, let's identify who hasn't paid for the current month
      final transactionsSnapshot = await firestore
          .collection('transactions')
          .where('category', isEqualTo: TransactionCategory.monthly.value)
          .get();
      
      final transactions = transactionsSnapshot.docs
          .map((doc) => FinancialTransaction.fromMap(doc.id, doc.data()))
          .toList();
      
      final currentMonthKey = '${now.month.toString().padLeft(2, '0')}-${now.year}';
      
      final paidUserIds = transactions.where((t) {
        if (t.coveredMonths != null) {
          return t.coveredMonths!.contains(currentMonthKey);
        }
        return t.date.year == now.year && t.date.month == now.month;
      }).map((t) => t.linkedUser).toSet();
      
      final debtors = users.where((u) => !paidUserIds.contains(u.uid)).toList();
      
      // 3. Send notifications
      for (var debtor in debtors) {
        final notificationDoc = firestore
            .collection('users')
            .doc(debtor.uid)
            .collection('notifications')
            .doc();
            
        await notificationDoc.set({
          'title': 'Monthly Contribution Reminder',
          'message': 'Dear ${debtor.fullName}, this is an automated reminder to pay your monthly contribution for $monthName.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'system',
        });
        
        // Note: In production, you would also trigger a push notification via FCM
        // but that requires a server-side component or Cloud Functions.
      }

      return Future.value(true);
    } catch (e) {
      print('Error in background task: $e');
      return Future.value(false);
    }
  });
}

class ReminderService {
  static const String taskName = "monthlyReminderTask";

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerTask() async {
    if (kIsWeb) return;
    // Schedule a periodic task to run every 24 hours
    // It will check inside the task if it's the 1st of the month
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
