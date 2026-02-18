import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FinancialTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FinancialTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all transactions (for President and Cashier)
  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      _transactions = snapshot.docs
          .map((doc) => FinancialTransaction.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user-specific transactions
  Future<void> loadUserTransactions(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('linkedUser', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      _transactions = snapshot.docs
          .map((doc) => FinancialTransaction.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load user transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create transaction (for Cashier and President)
  Future<bool> createTransaction(FinancialTransaction transaction) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      DocumentReference docRef =
      await _firestore.collection('transactions').add(transaction.toMap());

      // Add to local list with the generated ID
      FinancialTransaction newTransaction =
      transaction.copyWith(id: docRef.id);
      _transactions.insert(0, newTransaction);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create transaction: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update transaction (for Cashier and President)
  Future<bool> updateTransaction(FinancialTransaction transaction) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());

      // Update local list
      int index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update transaction: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete transaction (for Cashier and President)
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('transactions').doc(transactionId).delete();

      // Remove from local list
      _transactions.removeWhere((t) => t.id == transactionId);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete transaction: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get transactions by type
  List<FinancialTransaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((transaction) => transaction.type == type).toList();
  }

  // Get transactions by category
  List<FinancialTransaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions.where((transaction) => transaction.category == category).toList();
  }

  // Get transactions by date range
  List<FinancialTransaction> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((transaction) {
      return transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate total funds
  double getTotalFunds() {
    double credits = _transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);

    double debits = _transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);

    return credits - debits;
  }

  // Calculate total credits
  double getTotalCredits() {
    return _transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculate total debits
  double getTotalDebits() {
    return _transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get user's total contributions
  double getUserTotalContributions(String userId) {
    return _transactions
        .where((t) => t.linkedUser == userId && t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get monthly statistics
  Map<String, double> getMonthlyStatistics() {
    Map<String, double> stats = {};

    for (var transaction in _transactions) {
      String monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

      if (transaction.type == TransactionType.credit) {
        stats[monthKey] = (stats[monthKey] ?? 0) + transaction.amount;
      } else {
        stats[monthKey] = (stats[monthKey] ?? 0) - transaction.amount;
      }
    }

    return stats;
  }

  // Get category statistics (credits only)
  Map<TransactionCategory, double> getCategoryStatistics() {
    Map<TransactionCategory, double> stats = {};

    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.credit) {
        stats[transaction.category] =
            (stats[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return stats;
  }

  // Get recent transactions
  List<FinancialTransaction> getRecentTransactions({int limit = 10}) {
    List<FinancialTransaction> sorted = List.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));

    return sorted.take(limit).toList();
  }

  // Search transactions
  List<FinancialTransaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;

    String searchQuery = query.toLowerCase();
    return _transactions.where((transaction) {
      return transaction.category.value.toLowerCase().contains(searchQuery) ||
          transaction.description?.toLowerCase().contains(searchQuery) == true ||
          transaction.amount.toString().contains(searchQuery);
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Stream transactions for real-time updates
  Stream<List<FinancialTransaction>> streamTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          FinancialTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Stream user transactions for real-time updates
  Stream<List<FinancialTransaction>> streamUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('linkedUser', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
          FinancialTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
  // Check if user has paid for a specific month
  bool checkMonthlyPaymentStatus(String userId, int year, int month) {
    final targetMonthKey = '${month.toString().padLeft(2, '0')}-$year';

    return _transactions.any((t) {
      if (t.linkedUser != userId || t.type != TransactionType.credit) return false;
      if (t.category != TransactionCategory.monthly) return false;
      
      // Check explicit covered months
      if (t.coveredMonths != null) {
        return t.coveredMonths!.contains(targetMonthKey);
      }
      
      // Legacy: Match transaction date
      return t.date.year == year && t.date.month == month;
    });
  }

  // Get list of users who haven't paid for a specific month
  // Note: Requires passing the full list of users since TransactionProvider only knows about transactions
  List<String> getDebtorsForMonth(List<AppUser> allUsers, int year, int month) {
    final paidUserIds = _transactions
        .where((t) {
          if (t.type != TransactionType.credit || t.category != TransactionCategory.monthly) {
            return false;
          }
          
          final targetMonthKey = '${month.toString().padLeft(2, '0')}-$year';
          
          if (t.coveredMonths != null) {
            return t.coveredMonths!.contains(targetMonthKey);
          }
          
          return t.date.year == year && t.date.month == month;
        })
        .map((t) => t.linkedUser)
        .toSet();
        
    return allUsers
        .where((u) => u.role == UserRole.user && !paidUserIds.contains(u.uid))
        .map((u) => u.uid)
        .toList();
  }
}
