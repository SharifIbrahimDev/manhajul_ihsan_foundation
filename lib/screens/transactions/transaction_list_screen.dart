// // lib/screens/transactions/transaction_list_screen.dart
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import '../../providers/transaction_provider.dart';
//
// class TransactionListScreen extends StatelessWidget {
//   const TransactionListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final transactionProvider = Provider.of<TransactionProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Transaction List')),
//       body: ListView.builder(
//         itemCount: transactionProvider.transactions.length,
//         itemBuilder: (context, index) {
//           final tx = transactionProvider.transactions[index];
//           return ListTile(
//             title: Text('${tx.type} - ${tx.category}'),
//             subtitle: Text('Amount: ${tx.amount}'),
//             onTap: () => context.go('/transaction-form/${tx.id}'),
//           );
//         },
//       ),
//     );
//   }
// }