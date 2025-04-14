// lib/repositories/auth_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/services/api_service.dart';

class AuthRepository {
  final ApiService apiService;
  
  AuthRepository({required this.apiService});
  
  // Store auth token
  Future<void> _storeAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Get stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Check if user is logged in and get current user data
  Future<User?> getCurrentUser() async {
    final token = await getAuthToken();
    if (token == null) {
      return null;
    }
    
    try {
      final response = await apiService.get(
        endpoint: '/auth/me',
        requiresAuth: true,
      );
      
      return User.fromJson(response['data']);
    } catch (e) {
      return null;
    }
  }
  
  // Sign in user
  Future<User> signIn(String email, String password) async {
    try {
      final response = await apiService.post(
        endpoint: '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      
      final token = response['token'];
      await _storeAuthToken(token);
      return User.fromJson(response['user']);
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
      
      final response = await apiService.post(
        endpoint: '/auth/register',
        body: signUpData,
      );
      
      final token = response['token'];
      await _storeAuthToken(token);
      return User.fromJson(response['user']);
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }
  
  // Sign out user
  Future<void> signOut() async {
    try {
      final token = await getAuthToken();
      if (token != null) {
        await apiService.post(
          endpoint: '/auth/logout',
          requiresAuth: true,
        );
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
}