import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { president, registrar, cashier, user }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.president:
        return 'President';
      case UserRole.registrar:
        return 'Registrar';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.user:
        return 'User';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'president':
        return UserRole.president;
      case 'registrar':
        return UserRole.registrar;
      case 'cashier':
        return UserRole.cashier;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role.value,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'User'),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    UserRole? role,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TransactionType { credit, debit }
enum TransactionCategory { monthly, donation, marayu, taimako, maralafiya }

extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.credit:
        return 'credit';
      case TransactionType.debit:
        return 'debit';
    }
  }

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
      default:
        return TransactionType.debit;
    }
  }
}

extension TransactionCategoryExtension on TransactionCategory {
  String get value {
    switch (this) {
      case TransactionCategory.monthly:
        return 'Monthly';
      case TransactionCategory.donation:
        return 'Donation';
      case TransactionCategory.marayu:
        return 'Marayu';
      case TransactionCategory.taimako:
        return 'Taimako';
      case TransactionCategory.maralafiya:
        return 'Maralafiya';
    }
  }

  String get description {
    switch (this) {
      case TransactionCategory.monthly:
        return 'Monthly Contribution';
      case TransactionCategory.donation:
        return 'Donation';
      case TransactionCategory.marayu:
        return 'Support for Orphans';
      case TransactionCategory.taimako:
        return 'General Support';
      case TransactionCategory.maralafiya:
        return 'Medical Aid';
    }
  }

  static TransactionCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'monthly':
        return TransactionCategory.monthly;
      case 'donation':
        return TransactionCategory.donation;
      case 'marayu':
        return TransactionCategory.marayu;
      case 'taimako':
        return TransactionCategory.taimako;
      case 'maralafiya':
        return TransactionCategory.maralafiya;
      default:
        return TransactionCategory.monthly;
    }
  }
}

class FinancialTransaction {
  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String linkedUser;
  final String createdBy;
  final List<String>? coveredMonths; // Format: "MM-YYYY" (e.g., "01-2024", "02-2024")

  FinancialTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    required this.linkedUser,
    required this.createdBy,
    this.coveredMonths,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'category': category.value,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'linkedUser': linkedUser,
      'createdBy': createdBy,
      'coveredMonths': coveredMonths,
    };
  }

  factory FinancialTransaction.fromMap(String id, Map<String, dynamic> map) {
    return FinancialTransaction(
      id: id,
      type: TransactionTypeExtension.fromString(map['type'] ?? 'credit'),
      category: TransactionCategoryExtension.fromString(map['category'] ?? 'Monthly'),
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      linkedUser: map['linkedUser'] ?? '',
      createdBy: map['createdBy'] ?? '',
      coveredMonths: (map['coveredMonths'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  FinancialTransaction copyWith({
    String? id,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? linkedUser,
    String? createdBy,
    List<String>? coveredMonths,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      linkedUser: linkedUser ?? this.linkedUser,
      createdBy: createdBy ?? this.createdBy,
      coveredMonths: coveredMonths ?? this.coveredMonths,
    );
  }
}

