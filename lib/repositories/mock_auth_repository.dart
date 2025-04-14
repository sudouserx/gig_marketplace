// lib/repositories/auth_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/services/api_service.dart';
import 'package:gig_marketplace/services/mock_auth_service.dart'; // Import mock service

class MockAuthRepository {
  final ApiService? apiService;
  final MockAuthService mockAuthService =
      MockAuthService(); // Create mock service
  final bool useMock = true; // Flag to use mock or real service

  MockAuthRepository({this.apiService});

  // Store auth token
  Future<void> _storeAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    if (useMock) {
      return mockAuthService.getAuthToken();
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    }
  }

  // Check if user is logged in and get current user data
  Future<User?> getCurrentUser() async {
    if (useMock) {
      final response = await mockAuthService.getUser();
      if (response == null || response['data'] == null) return null;
      return User.fromJson(response['data']);
    } else {
      final token = await getAuthToken();
      if (token == null) {
        return null;
      }

      try {
        final response = await apiService!.get(
          endpoint: '/auth/me',
          requiresAuth: true,
        );

        return User.fromJson(response['data']);
      } catch (e) {
        return null;
      }
    }
  }

  // Sign in user
  Future<User> signIn(String email, String password) async {
    try {
      if (useMock) {
        final response = await mockAuthService.signIn(email, password);
        final token = response['token'];
        await _storeAuthToken(token);
        return User.fromJson(response['user']);
      } else {
        final response = await apiService!.post(
          endpoint: '/auth/login',
          body: {
            'email': email,
            'password': password,
          },
        );

        final token = response['token'];
        await _storeAuthToken(token);
        return User.fromJson(response['user']);
      }
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign up user
  Future<User> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? companyName,
    String? businessRegistrationNumber,
    String? resumeUrl,
  }) async {
    try {
      if (useMock) {
        final response = await mockAuthService.signUp(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          role: role,
          companyName: companyName,
          businessRegistrationNumber: businessRegistrationNumber,
          resumeUrl: resumeUrl,
        );

        final token = response['token'];
        await _storeAuthToken(token);
        return User.fromJson(response['user']);
      } else {
        final Map<String, dynamic> signUpData = {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'role': role == UserRole.employer ? 'employer' : 'employee',
        };

        // Add role-specific fields
        if (role == UserRole.employer) {
          signUpData['companyName'] = companyName;
          signUpData['businessRegistrationNumber'] = businessRegistrationNumber;
        } else if (role == UserRole.employee && resumeUrl != null) {
          signUpData['resumeUrl'] = resumeUrl;
        }

        final response = await apiService!.post(
          endpoint: '/auth/register',
          body: signUpData,
        );

        final token = response['token'];
        await _storeAuthToken(token);
        return User.fromJson(response['user']);
      }
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      if (useMock) {
        await mockAuthService.signOut();
      } else {
        final token = await getAuthToken();
        if (token != null) {
          await apiService!.post(
            endpoint: '/auth/logout',
            requiresAuth: true,
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
}
