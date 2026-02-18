// // lib/core/services/auth_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../models/user_model.dart';
// import '../constants/firestore_paths.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   User? get currentUser => _auth.currentUser;
//
//   Stream<UserModel?> getUserStream(String uid) {
//     return _firestore.collection(FirestorePaths.usersCollection).doc(uid).snapshots().map((doc) {
//       if (doc.exists) return UserModel.fromMap(doc.data()!);
//       return null;
//     });
//   }
//
//   Future<void> register({
//     required String email,
//     required String password,
//     required String fullName,
//     required String phone,
//     required String address,
//   }) async {
//     UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
//     String uid = cred.user!.uid;
//
//     QuerySnapshot users = await _firestore.collection(FirestorePaths.usersCollection).get();
//     String role = users.docs.isEmpty ? 'President' : 'User';
//
//     UserModel newUser = UserModel(
//       uid: uid,
//       fullName: fullName,
//       email: email,
//       phone: phone,
//       address: address,
//       role: role,
//       createdAt: Timestamp.now(),
//       updatedAt: Timestamp.now(),
//     );
//
//     await _firestore.collection(FirestorePaths.usersCollection).doc(uid).set(newUser.toMap());
//   }
//
//   Future<void> login(String email, String password) async {
//     await _auth.signInWithEmailAndPassword(email: email, password: password);
//   }
//
//   Future<void> logout() async {
//     await _auth.signOut();
//   }
// }