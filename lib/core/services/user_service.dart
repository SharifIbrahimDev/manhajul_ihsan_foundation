// // lib/core/services/user_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../models/user_model.dart';
// import '../constants/firestore_paths.dart';
//
// class UserService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> updateUser(UserModel user) async {
//     await _firestore.collection(FirestorePaths.usersCollection).doc(user.uid).update(user.toMap());
//   }
//
//   Future<void> deleteUser(String uid) async {
//     await _firestore.collection(FirestorePaths.usersCollection).doc(uid).delete();
//   }
//
//   Stream<List<UserModel>> getAllUsers() {
//     return _firestore.collection(FirestorePaths.usersCollection).snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
//     });
//   }
//
//   Future<UserModel?> getUser(String uid) async {
//     DocumentSnapshot doc = await _firestore.collection(FirestorePaths.usersCollection).doc(uid).get();
//     if (doc.exists) return UserModel.fromMap(doc.data() as Map<String, dynamic>);
//     return null;
//   }
//
//   Future<void> updateRole(String userId, String newRole) async {
//     await _firestore.collection(FirestorePaths.usersCollection).doc(userId).update({
//       'role': newRole,
//       'updatedAt': Timestamp.now(),
//     });
//   }
// }