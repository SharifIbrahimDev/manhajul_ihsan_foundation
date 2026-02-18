// // lib/models/user_model.dart (same as before)
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserModel {
//   final String uid;
//   final String fullName;
//   final String email;
//   final String phone;
//   final String address;
//   final String role;
//   final Timestamp createdAt;
//   final Timestamp updatedAt;
//
//   UserModel({
//     required this.uid,
//     required this.fullName,
//     required this.email,
//     required this.phone,
//     required this.address,
//     required this.role,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//
//   factory UserModel.fromMap(Map<String, dynamic> map) {
//     return UserModel(
//       uid: map['uid'],
//       fullName: map['fullName'],
//       email: map['email'],
//       phone: map['phone'],
//       address: map['address'],
//       role: map['role'],
//       createdAt: map['createdAt'],
//       updatedAt: map['updatedAt'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'fullName': fullName,
//       'email': email,
//       'phone': phone,
//       'address': address,
//       'role': role,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//     };
//   }
// }