// lib/repositories/user_repository.dart
import 'dart:io';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/services/api_service.dart';

class UserRepository {
  final ApiService apiService;

  UserRepository({required this.apiService});

  // Get user profile by ID
  Future<User> getUserProfile(String userId) async {
    try {
      final response = await apiService.get(
        endpoint: '/auth/users/$userId',
        // requiresAuth: true,
      );

      print(response);
      return User.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<User> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? bio,
    File? profilePicture,
    File? resume,
    String? companyName,
    String? businessRegistrationNumber,
  }) async {
    try {
      // Create form data for multipart request
      final Map<String, dynamic> fields = {};
      final Map<String, File> files = {};

      // Add text fields if they exist
      if (fullName != null) fields['fullName'] = fullName;
      if (phoneNumber != null) fields['phoneNumber'] = phoneNumber;
      if (bio != null) fields['bio'] = bio;
      if (companyName != null) fields['companyName'] = companyName;
      if (businessRegistrationNumber != null) {
        fields['businessRegistrationNumber'] = businessRegistrationNumber;
      }

      // Add files if they exist
      if (profilePicture != null) files['profilePicture'] = profilePicture;
      if (resume != null) files['resume'] = resume;

      final response = await apiService.multipartRequest(
        method: 'PUT',
        endpoint: '/users/$userId',
        fields: fields,
        files: files,
        requiresAuth: true,
      );

      return User.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }
}
