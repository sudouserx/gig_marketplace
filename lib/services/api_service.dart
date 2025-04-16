// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'https://adjusted-fish-finally.ngrok-free.app/api';
  String? _cachedToken;

  // Get auth token (either from cache or storage)
  Future<String?> _getAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    // This creates a circular dependency but we'll fix it with a provider
    // See note below about fixing this
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Handle response and extract data or throw error
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final message = errorBody['message'] ?? 'An error occurred';
      throw Exception(message);
    }
  }

  // Helper to get headers
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    // Add Accept header to explicitly request JSON
    headers['Accept'] = 'application/json';

    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

// In api_service.dart, modify the get method
  Future<dynamic> get({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final uri = Uri.parse('$baseUrl$endpoint');

      print('Sending GET request to: $uri');
      print('Request headers: $headers');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      // For debugging, print the full response body
      print('Full response body:');
      print(response.body);

      // Try to parse the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('JSON parse error: $e');
          throw Exception('Failed to parse JSON response');
        }
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('GET Request Error: ${e.toString()}');
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      print('Sending POST request to: $baseUrl$endpoint');
      print('Request body: ${body != null ? jsonEncode(body) : 'null'}');

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      print('Request headers: $headers');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      throw Exception(
          'Network error: No internet connection. Please check your connection and try again.');
    } on http.ClientException catch (e) {
      print('ClientException: ${e.toString()}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // PUT request
  Future<dynamic> put({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // PATCH request
  Future<dynamic> patch({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // DELETE request
  Future<dynamic> delete({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // Multipart request (for file uploads)
  Future<dynamic> multipartRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? fields,
    Map<String, File>? files,
    Map<String, List<File>>? multipleFiles,
    bool requiresAuth = false,
  }) async {
    final request = http.MultipartRequest(
      method,
      Uri.parse('$baseUrl$endpoint'),
    );

    // Add authorization header if required
    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add text fields if they exist
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });
    }

    // Add single files if they exist
    if (files != null) {
      await Future.forEach(files.entries, (MapEntry<String, File> entry) async {
        final file = entry.value;
        final mimeType = lookupMimeType(file.path);
        final multipartFile = await http.MultipartFile.fromPath(
          entry.key,
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
        request.files.add(multipartFile);
      });
    }

    // Add multiple files if they exist
    if (multipleFiles != null) {
      await Future.forEach(multipleFiles.entries,
          (MapEntry<String, List<File>> entry) async {
        final fieldName = entry.key;
        final fileList = entry.value;

        for (final file in fileList) {
          final mimeType = lookupMimeType(file.path);
          final multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          );
          request.files.add(multipartFile);
        }
      });
    }

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
