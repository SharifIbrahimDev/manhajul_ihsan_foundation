// // lib/screens/users/user_detail_screen.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../core/services/user_service.dart';
// import '../../core/utils/validators.dart';
// import '../../core/widgets/custom_buttons.dart';
// import '../../core/widgets/custom_textfield.dart';
// import '../../models/user_model.dart';
// import '../../providers/user_provider.dart';
//
// class UserDetailScreen extends StatefulWidget {
//   final String userId;
//
//   const UserDetailScreen({super.key, required this.userId});
//
//   @override
//   State<UserDetailScreen> createState() => _UserDetailScreenState();
// }
//
// class _UserDetailScreenState extends State<UserDetailScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _fullNameController;
//   late TextEditingController _emailController;
//   late TextEditingController _phoneController;
//   late TextEditingController _addressController;
//   UserModel? _user;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }
//
//   Future<void> _loadUser() async {
//     _user = await UserService().getUser(widget.userId);
//     if (_user != null) {
//       _fullNameController = TextEditingController(text: _user!.fullName);
//       _emailController = TextEditingController(text: _user!.email);
//       _phoneController = TextEditingController(text: _user!.phone);
//       _addressController = TextEditingController(text: _user!.address);
//       setState(() {});
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//
//     if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('User Detail')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               CustomTextField(controller: _fullNameController, label: 'Full Name', validator: Validators.validateName),
//               CustomTextField(controller: _emailController, label: 'Email', validator: Validators.validateEmail),
//               CustomTextField(controller: _phoneController, label: 'Phone', validator: Validators.validatePhone),
//               CustomTextField(controller: _addressController, label: 'Address'),
//               CustomButton(
//                 text: 'Update',
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     final updatedUser = UserModel(
//                       uid: _user!.uid,
//                       fullName: _fullNameController.text,
//                       email: _emailController.text,
//                       phone: _phoneController.text,
//                       address: _addressController.text,
//                       role: _user!.role,
//                       createdAt: _user!.createdAt,
//                       updatedAt: Timestamp.now(),
//                     );
//                     await userProvider.updateUser(updatedUser);
//                     Navigator.pop(context);
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }