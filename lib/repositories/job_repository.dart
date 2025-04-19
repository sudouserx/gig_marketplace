// lib/repositories/job_repository.dart
import 'dart:io';
import 'dart:js_interop';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/services/api_service.dart';

class JobRepository {
  final ApiService apiService;

  JobRepository({required this.apiService});

  // Get all jobs with optional filters
  Future<List<Job>> getJobs({Map<String, dynamic>? filters}) async {
    try {
      final response = await apiService.get(
        endpoint: '/jobs',
        queryParams: filters,
        requiresAuth: true,
      );
      // Extract the data array from the response
      final List<dynamic> jobsData = response['data'];

      // Make sure we're properly iterating through each job in the data array
      final check = jobsData.map((jobData) => Job.fromJson(jobData)).toList();
      print("check at the job repository: $check");
      return check;

    } catch (e) {
      throw Exception('Failed to get jobs: ${e.toString()}');
    }
  }

  // Get jobs by employer ID
  Future<List<Job>> getEmployerJobs({required String employerId, Map<String, dynamic>? filters}) async {
    try {
      final response = await apiService.get(
        endpoint: '/jobs/employers/$employerId/jobs',
        queryParams: filters,
        requiresAuth: true,
      );

      final List<dynamic> jobsData = response['data'];
      return jobsData.map((jobData) => Job.fromJson(jobData)).toList();
    } catch (e) {
      throw Exception('Failed to get employer jobs: ${e.toString()}');
    }
  }

  // Create a new job
  Future<Job> createJob({
    required String employerId,
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    required String location,
    required bool isRemote,
    required DateTime deadline,
    double? budget,
    List<File>? mediaUrls,
  }) async {
    try {
      // Create form data for multipart request
      final Map<String, dynamic> fields = {
        'employerId': employerId,
        'title': title,
        'description': description,
        'category': category,
        'tags': tags, // ApiService will handle the JSON encoding
        'location': location,
        'isRemote': isRemote.toString(),
        'deadline': deadline.toIso8601String(),
      };
      
      if (budget != null) fields['budget'] = budget.toString();
      
      final Map<String, List<File>> multipleFiles = {};
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        multipleFiles['mediaUrls'] = mediaUrls;
      }

      final response = await apiService.multipartRequest(
        method: 'POST',
        endpoint: '/jobs',
        fields: fields,
        multipleFiles: multipleFiles,
        requiresAuth: true,
      );

      return Job.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to create job: ${e.toString()}');
    }
  }

  // Update existing job
  Future<Job> updateJob({
    required String jobId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? location,
    bool? isRemote,
    DateTime? deadline,
    double? budget,
    List<File>? mediaUrls,
  }) async {
    try {
      // Create form data for multipart request
      final Map<String, dynamic> fields = {};
      
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (category != null) fields['category'] = category;
      if (tags != null) fields['tags'] = tags.toString(); // ApiService will handle the JSON encoding
      if (location != null) fields['location'] = location;
      if (isRemote != null) fields['isRemote'] = isRemote.toString();
      if (deadline != null) fields['deadline'] = deadline.toIso8601String();
      if (budget != null) fields['budget'] = budget.toString();
      
      final Map<String, List<File>> multipleFiles = {};
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        multipleFiles['mediaUrls'] = mediaUrls;
      }

      final response = await apiService.multipartRequest(
        method: 'PUT',
        endpoint: '/jobs/$jobId',
        fields: fields,
        multipleFiles: multipleFiles,
        requiresAuth: true,
      );

      return Job.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update job: ${e.toString()}');
    }
  }

  // Delete job
  Future<void> deleteJob({required String jobId}) async {
    try {
      await apiService.delete(
        endpoint: '/jobs/$jobId',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete job: ${e.toString()}');
    }
  }

  // Get job details by ID
  Future<Job> getJobDetails({required String jobId}) async {
    try {
      final response = await apiService.get(
        endpoint: '/jobs/$jobId',
        requiresAuth: true,
      );
      

      return Job.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to get job details: ${e.toString()}');
    }
  }
}