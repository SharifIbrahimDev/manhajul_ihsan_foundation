// // lib/screens/users/user_list_screen.dart
// // This can be part of dashboards, but for completeness
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
//
// import '../../providers/user_provider.dart';
//
// class UserListScreen extends StatelessWidget {
//   const UserListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('User List')),
//       body: ListView.builder(
//         itemCount: userProvider.users.length,
//         itemBuilder: (context, index) {
//           final user = userProvider.users[index];
//           return ListTile(
//             title: Text(user.fullName),
//             onTap: () => context.go('/user-detail/${user.uid}'),
//           );
//         },
//       ),
//     );
//   }
// }