// lib/repositories/user_repository.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/services/api_service.dart';

class UserRepository {
  final ApiService apiService;

  UserRepository({required this.apiService});

// In user_repository.dart
  Future<User> getUserProfile(String userId) async {
    try {
      // Try a direct HTTP request instead of using the service
      final response = await http.get(
        Uri.parse(
            'https://adjusted-fish-finally.ngrok-free.app/api/auth/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Direct request status: ${response.statusCode}');
      print('Direct request headers: ${response.headers}');
      print('Direct request body preview: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final userData = jsonDecode(response.body);
          return User.fromJson(userData);
        } catch (e) {
          print('JSON parse error in direct request: $e');
          throw Exception('Failed to parse JSON response from direct request');
        }
      } else {
        throw Exception(
            'Direct request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in direct user profile request: $e');

      // If the direct request fails, fall back to the original method
      try {
        final response = await apiService.get(
          endpoint: '/auth/users/$userId',
          additionalHeaders: {'Accept': 'application/json'},
        );

        return User.fromJson(response);
      } catch (e) {
        print('Error getting user profile via service: $e');
        throw Exception('Failed to get user profile: ${e.toString()}');
      }
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
