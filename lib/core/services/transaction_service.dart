// // lib/core/services/transaction_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/transaction_model.dart';
// import '../constants/firestore_paths.dart';
//
// class TransactionService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<String> createTransaction(TransactionModel transaction) async {
//     DocumentReference ref = await _firestore.collection(FirestorePaths.transactionsCollection).add(transaction.toMap());
//     return ref.id;
//   }
//
//   Future<void> updateTransaction(String id, TransactionModel transaction) async {
//     await _firestore.collection(FirestorePaths.transactionsCollection).doc(id).update(transaction.toMap());
//   }
//
//   Future<void> deleteTransaction(String id) async {
//     await _firestore.collection(FirestorePaths.transactionsCollection).doc(id).delete();
//   }
//
//   Stream<List<TransactionModel>> getAllTransactions() {
//     return _firestore.collection(FirestorePaths.transactionsCollection).snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();
//     });
//   }
//
//   Stream<List<TransactionModel>> getUserTransactions(String uid) {
//     return _firestore
//         .collection(FirestorePaths.transactionsCollection)
//         .where('linkedUser', isEqualTo: uid)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();
//     });
//   }
//
//   Stream<double> getTotalFunds() {
//     return _firestore.collection(FirestorePaths.transactionsCollection).snapshots().map((snapshot) {
//       double total = 0;
//       for (var doc in snapshot.docs) {
//         double amount = doc['amount'].toDouble();
//         total += doc['type'] == 'credit' ? amount : -amount;
//       }
//       return total;
//     });
//   }
// }