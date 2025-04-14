// lib/models/user.dart
enum UserRole { employer, employee }

class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String? profilePicture;
  final String? bio;
  final double? rating;
  final String? resumeUrl;  // For employees
  final String? companyName;  // For employers
  final String? businessRegistrationNumber;  // For employers

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profilePicture,
    this.bio,
    this.rating,
    this.resumeUrl,
    this.companyName,
    this.businessRegistrationNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] == 'employer' ? UserRole.employer : UserRole.employee,
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      rating: json['rating']?.toDouble(),
      resumeUrl: json['resumeUrl'],
      companyName: json['companyName'],
      businessRegistrationNumber: json['businessRegistrationNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role == UserRole.employer ? 'employer' : 'employee',
      'profilePicture': profilePicture,
      'bio': bio,
      'rating': rating,
      'resumeUrl': resumeUrl,
      'companyName': companyName,
      'businessRegistrationNumber': businessRegistrationNumber,
    };
  }
}