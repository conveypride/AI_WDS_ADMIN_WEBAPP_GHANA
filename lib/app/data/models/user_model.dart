import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // e.g., "cafo_forecaster", "cafo_super_admin", "marine_forecaster"
  final String department; // e.g., "All", "Cafo", "Marine"
  final String language;
  final List<String> followedGroups;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.language,
    required this.followedGroups,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'public',
      department: data['department'] ?? '',
      language: data['language'] ?? 'English',
      followedGroups: List<String>.from(data['followed_groups'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'language': language,
      'followed_groups': followedGroups,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}