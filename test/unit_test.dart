import 'package:flutter_test/flutter_test.dart';
import 'package:manhajul_ihsan_foundation/models/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AppUser Model Tests', () {
    test('AppUser fromMap creates valid object', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final map = {
        'uid': 'test_uid',
        'fullName': 'Test User',
        'email': 'test@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'role': 'President',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      final user = AppUser.fromMap(map);

      expect(user.uid, 'test_uid');
      expect(user.fullName, 'Test User');
      expect(user.role, UserRole.president);
      expect(user.createdAt.year, now.year);
    });

    test('AppUser toMap returns correct map', () {
      final now = DateTime.now();
      final user = AppUser(
        uid: 'test_uid',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        address: 'Test Address',
        role: UserRole.cashier,
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();

      expect(map['uid'], 'test_uid');
      expect(map['role'], 'Cashier');
      expect(map['createdAt'], isA<Timestamp>());
    });
   group('FinancialTransaction Model Tests', () {
    test('FinancialTransaction fromMap creates valid object', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final map = {
        'type': 'credit',
        'category': 'Monthly',
        'amount': 5000.0,
        'date': timestamp,
        'description': 'Test contribution',
        'linkedUser': 'user_123',
        'createdBy': 'cashier_456',
      };

      final transaction = FinancialTransaction.fromMap('id_789', map);

      expect(transaction.id, 'id_789');
      expect(transaction.type, TransactionType.credit);
      expect(transaction.category, TransactionCategory.monthly);
      expect(transaction.amount, 5000.0);
      expect(transaction.linkedUser, 'user_123');
    });

    test('FinancialTransaction toMap returns correct map', () {
      final now = DateTime.now();
      final transaction = FinancialTransaction(
        id: 'id_789',
        type: TransactionType.debit,
        category: TransactionCategory.marayu,
        amount: 2500.0,
        date: now,
        description: 'Orphan support',
        linkedUser: 'user_123',
        createdBy: 'cashier_456',
      );

      final map = transaction.toMap();

      expect(map['type'], 'debit');
      expect(map['category'], 'Marayu');
      expect(map['amount'], 2500.0);
      expect(map['linkedUser'], 'user_123');
    });
  });
});
}
