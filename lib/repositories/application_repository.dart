// lib/repositories/application_repository.dart
import 'package:gig_marketplace/models/job_application.dart';
import 'package:gig_marketplace/services/api_service.dart';

class ApplicationRepository {
  final ApiService apiService;

  ApplicationRepository({required this.apiService});

  // Get applications by employee ID
  Future<List<JobApplication>> getAppliedJobs({required String employeeId}) async {
    try {
      final response = await apiService.get(
        endpoint: '/employees/$employeeId/applications',
        requiresAuth: true,
      );

      final List<dynamic> applicationsData = response['data'];
      return applicationsData.map((appData) => JobApplication.fromJson(appData)).toList();
    } catch (e) {
      throw Exception('Failed to get applied jobs: ${e.toString()}');
    }
  }

  // Get applicants for a job
  Future<List<JobApplication>> getJobApplicants({required String jobId}) async {
    try {
      final response = await apiService.get(
        endpoint: '/jobs/$jobId/applications',
        requiresAuth: true,
      );

      final List<dynamic> applicantsData = response['data'];
      return applicantsData.map((appData) => JobApplication.fromJson(appData)).toList();
    } catch (e) {
      throw Exception('Failed to get job applicants: ${e.toString()}');
    }
  }

  // Apply for a job
  Future<JobApplication> applyForJob({
    required String jobId,
    required String employeeId,
    String? coverLetter,
  }) async {
    try {
      final Map<String, dynamic> applicationData = {
        'jobId': jobId,
        'employeeId': employeeId,
      };

      if (coverLetter != null) {
        applicationData['coverLetter'] = coverLetter;
      }

      final response = await apiService.post(
        endpoint: '/applications',
        body: applicationData,
        requiresAuth: true,
      );

      return JobApplication.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to apply for job: ${e.toString()}');
    }
  }

  // Update application status
  Future<JobApplication> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    try {
      final String statusString;
      switch (newStatus) {
        case ApplicationStatus.pending:
          statusString = 'pending';
          break;
        case ApplicationStatus.shortlisted:
          statusString = 'shortlisted';
          break;
        case ApplicationStatus.rejected:
          statusString = 'rejected';
          break;
        case ApplicationStatus.hired:
          statusString = 'hired';
          break;
      }

      final response = await apiService.patch(
        endpoint: '/applications/$applicationId',
        body: {'status': statusString},
        requiresAuth: true,
      );

      return JobApplication.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update application status: ${e.toString()}');
    }
  }
}