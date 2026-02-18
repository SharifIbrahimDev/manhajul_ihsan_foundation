import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all users (for President and Registrar)
  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort users by role and name
      _users.sort((a, b) {
        int roleComparison = _getRolePriority(a.role).compareTo(_getRolePriority(b.role));
        if (roleComparison != 0) return roleComparison;
        return a.fullName.compareTo(b.fullName);
      });

    } catch (e) {
      _errorMessage = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new user (for Registrar)
  Future<bool> createUser(AppUser user) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      // Add to local list
      _users.add(user);
      _sortUsers();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user (for Registrar and President)
  Future<bool> updateUser(AppUser user) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      AppUser updatedUser = user.copyWith(updatedAt: DateTime.now());

      await _firestore.collection('users').doc(user.uid).update(updatedUser.toMap());

      // Update local list
      int index = _users.indexWhere((u) => u.uid == user.uid);
      if (index != -1) {
        _users[index] = updatedUser;
        _sortUsers();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user (for Registrar)
  Future<bool> deleteUser(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('users').doc(uid).delete();

      // Remove from local list
      _users.removeWhere((user) => user.uid == uid);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user role (for President only)
  Future<bool> updateUserRole(String uid, UserRole newRole) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore.collection('users').doc(uid).update({
        'role': newRole.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local list
      int index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          role: newRole,
          updatedAt: DateTime.now(),
        );
        _sortUsers();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user role: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get users by role (async)
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      // First check local list
      List<AppUser> localUsers = _users.where((user) => user.role == role).toList();
      if (localUsers.isNotEmpty) return localUsers;

      // If not loaded, fetch from Firestore
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.value)
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching users by role: $e');
      return [];
    }
  }

  // Get user by ID
  AppUser? getUserById(String uid) {
    try {
      return _users.firstWhere((user) => user.uid == uid);
    } catch (e) {
      return null;
    }
  }

  // Search users
  List<AppUser> searchUsers(String query) {
    if (query.isEmpty) return _users;

    String searchQuery = query.toLowerCase();
    return _users.where((user) {
      return user.fullName.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery) ||
          user.phone.contains(searchQuery);
    }).toList();
  }

  // Get role statistics
  Map<UserRole, int> getRoleStatistics() {
    Map<UserRole, int> stats = {
      UserRole.president: 0,
      UserRole.registrar: 0,
      UserRole.cashier: 0,
      UserRole.user: 0,
    };

    for (var user in _users) {
      stats[user.role] = (stats[user.role] ?? 0) + 1;
    }

    return stats;
  }

  void _sortUsers() {
    _users.sort((a, b) {
      int roleComparison = _getRolePriority(a.role).compareTo(_getRolePriority(b.role));
      if (roleComparison != 0) return roleComparison;
      return a.fullName.compareTo(b.fullName);
    });
  }

  int _getRolePriority(UserRole role) {
    switch (role) {
      case UserRole.president:
        return 1;
      case UserRole.registrar:
        return 2;
      case UserRole.cashier:
        return 3;
      case UserRole.user:
        return 4;
    }
  }



  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Stream users for real-time updates
  Stream<List<AppUser>> streamUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}