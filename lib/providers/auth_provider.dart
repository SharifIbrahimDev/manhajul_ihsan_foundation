import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
        await updateFcmToken();
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _loadUserData(result.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> register(String email, String password, String fullName,
      String phone, String address) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check if this is the first user (should be President)
      QuerySnapshot existingUsers = await _firestore.collection('users').limit(1).get();
      UserRole role = existingUsers.docs.isEmpty ? UserRole.president : UserRole.user;

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        AppUser newUser = AppUser(
          uid: result.user!.uid,
          fullName: fullName,
          email: email,
          phone: phone,
          address: address,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());

        _appUser = newUser;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _appUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
    }
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool hasRole(UserRole role) {
    return _appUser?.role == role;
  }

  bool hasAnyRole(List<UserRole> roles) {
    return _appUser != null && roles.contains(_appUser!.role);
  }

  void updateAppUser(AppUser updatedUser) {
    _appUser = updatedUser;
    notifyListeners();
  }

  Future<void> updateFcmToken() async {
    if (_user == null) return;

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> refreshUserData() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
      notifyListeners();
    }
  }
}