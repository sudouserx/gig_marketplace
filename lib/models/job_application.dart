// lib/models/job_application.dart
enum ApplicationStatus { pending, shortlisted, rejected, hired }

class JobApplication {
  final String id;
  final String jobId;
  final String employeeId;
  final String employeeName;
  final String? employeeProfilePicture;
  final double? employeeRating;
  final String? resumeUrl;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? coverLetter;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.employeeId,
    required this.employeeName,
    this.employeeProfilePicture,
    this.employeeRating,
    this.resumeUrl,
    required this.status,
    required this.appliedAt,
    this.coverLetter,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'],
      jobId: json['jobId'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      employeeProfilePicture: json['employeeProfilePicture'],
      employeeRating: json['employeeRating']?.toDouble(),
      resumeUrl: json['resumeUrl'],
      status: _parseApplicationStatus(json['status']),
      appliedAt: DateTime.parse(json['appliedAt']),
      coverLetter: json['coverLetter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeProfilePicture': employeeProfilePicture,
      'employeeRating': employeeRating,
      'resumeUrl': resumeUrl,
      'status': _applicationStatusToString(status),
      'appliedAt': appliedAt.toIso8601String(),
      'coverLetter': coverLetter,
    };
  }

  static ApplicationStatus _parseApplicationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'hired':
        return ApplicationStatus.hired;
      default:
        return ApplicationStatus.pending;
    }
  }

  static String _applicationStatusToString(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'pending';
      case ApplicationStatus.shortlisted:
        return 'shortlisted';
      case ApplicationStatus.rejected:
        return 'rejected';
      case ApplicationStatus.hired:
        return 'hired';
    }
  }
}