// // lib/models/transaction_model.dart (same as before)
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class TransactionModel {
//   final String id;
//   final String type;
//   final String category;
//   final double amount;
//   final Timestamp date;
//   final String? description;
//   final String linkedUser;
//   final String createdBy;
//
//   TransactionModel({
//     required this.id,
//     required this.type,
//     required this.category,
//     required this.amount,
//     required this.date,
//     this.description,
//     required this.linkedUser,
//     required this.createdBy,
//   });
//
//   factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
//     return TransactionModel(
//       id: id,
//       type: map['type'],
//       category: map['category'],
//       amount: map['amount'].toDouble(),
//       date: map['date'],
//       description: map['description'],
//       linkedUser: map['linkedUser'],
//       createdBy: map['createdBy'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'type': type,
//       'category': category,
//       'amount': amount,
//       'date': date,
//       'description': description,
//       'linkedUser': linkedUser,
//       'createdBy': createdBy,
//     };
//   }
// }