// lib/services/mock_auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gig_marketplace/models/user.dart';

class MockAuthService {
  // Mock user database
  final Map<String, Map<String, dynamic>> _users = {
    'test@example.com': {
      'id': '1',
      'fullName': 'Test User',
      'email': 'test@example.com',
      'phoneNumber': '123-456-7890',
      'role': 'employee',
      'resumeUrl': 'mock-resume.pdf',
      'bio':
          'Experienced freelancer with skills in web development and design.',
      'rating': 4.7,
      'password': 'password123', // In a real app, never store plain passwords!
    },
    'employer@example.com': {
      'id': '2',
      'fullName': 'Employer User',
      'email': 'employer@example.com',
      'phoneNumber': '987-654-3210',
      'role': 'employer',
      'companyName': 'Test Company',
      'businessRegistrationNumber': 'ABC123456',
      'bio': 'Technology company looking for talented professionals.',
      'rating': 4.9,
      'password': 'password123', // In a real app, never store plain passwords!
    },
  };

  // Generate a mock token
  String _generateToken(String email) {
    final payload = {
      'email': email,
      'exp':
          DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/
              1000,
    };
    return base64Encode(utf8.encode(json.encode(payload)));
  }

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

  // Store current user
  Future<void> _storeCurrentUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(userData));
  }

  // Get current user from storage
  Future<Map<String, dynamic>?> _getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('current_user');
    if (userStr == null) return null;
    return json.decode(userStr) as Map<String, dynamic>;
  }

  // Mock delay to simulate network request
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Sign in
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    await _simulateNetworkDelay();

    // Check if user exists
    if (!_users.containsKey(email)) {
      throw Exception('User not found');
    }

    // Check password
    final userData = _users[email]!;
    if (userData['password'] != password) {
      throw Exception('Invalid password');
    }

    // Generate token
    final token = _generateToken(email);
    await _storeAuthToken(token);

    // Store user data
    final userToStore = Map<String, dynamic>.from(userData);
    userToStore.remove('password'); // Remove password before storing
    await _storeCurrentUser(userToStore);

    return {
      'token': token,
      'user': userToStore,
    };
  }

  // Sign up
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? companyName,
    String? businessRegistrationNumber,
    String? resumeUrl,
  }) async {
    await _simulateNetworkDelay();

    // Check if user already exists
    if (_users.containsKey(email)) {
      throw Exception('Email already in use');
    }

    // Create new user
    final String roleStr = role == UserRole.employer ? 'employer' : 'employee';
    final newUserId = (_users.length + 1).toString();

    final Map<String, dynamic> newUser = {
      'id': newUserId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password, // In a real app, encrypt passwords!
      'role': roleStr,
      'rating': 0.0,
    };

    // Add role-specific fields
    if (role == UserRole.employer) {
      newUser['companyName'] = companyName;
      newUser['businessRegistrationNumber'] = businessRegistrationNumber;
    } else if (role == UserRole.employee) {
      newUser['resumeUrl'] = resumeUrl;
    }

    // Add to mock database
    _users[email] = newUser;

    // Generate token
    final token = _generateToken(email);
    await _storeAuthToken(token);

    // Store user data
    final userToStore = Map<String, dynamic>.from(newUser);
    userToStore.remove('password'); // Remove password before storing
    await _storeCurrentUser(userToStore);

    return {
      'token': token,
      'user': userToStore,
    };
  }

  // Get user data
  Future<Map<String, dynamic>?> getUser() async {
    await _simulateNetworkDelay();

    final token = await getAuthToken();
    if (token == null) {
      return null;
    }

    try {
      final userData = await _getStoredUser();
      if (userData == null) {
        return null;
      }

      return {'data': userData};
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<Map<String, dynamic>> signOut() async {
    await _simulateNetworkDelay();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');

    return {'success': true};
  }
}
