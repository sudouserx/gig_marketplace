// lib/models/job.dart
import 'package:intl/intl.dart';

enum JobStatus { active, filled, expired }

class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String location;
  final bool isRemote;
  final DateTime deadline;
  final double? budget;
  final JobStatus status;
  final DateTime createdAt;
  final List<String>? mediaUrls;
  final int applicantCount;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.location,
    required this.isRemote,
    required this.deadline,
    this.budget,
    required this.status,
    required this.createdAt,
    this.mediaUrls,
    this.applicantCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      employerId: json['employerId'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      tags: List<String>.from(json['tags']),
      location: json['location'],
      isRemote: json['isRemote'],
      deadline: DateTime.parse(json['deadline']),
      budget: json['budget']?.toDouble(),
      status: _parseJobStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      mediaUrls: json['mediaUrls'] != null ? List<String>.from(json['mediaUrls']) : null,
      applicantCount: json['applicantCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employerId': employerId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'location': location,
      'isRemote': isRemote,
      'deadline': deadline.toIso8601String(),
      'budget': budget,
      'status': _jobStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'mediaUrls': mediaUrls,
      'applicantCount': applicantCount,
    };
  }

  String get formattedDeadline {
    return DateFormat('MMM dd, yyyy').format(deadline);
  }

  static JobStatus _parseJobStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return JobStatus.active;
      case 'filled':
        return JobStatus.filled;
      case 'expired':
        return JobStatus.expired;
      default:
        return JobStatus.active;
    }
  }

  static String _jobStatusToString(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return 'active';
      case JobStatus.filled:
        return 'filled';
      case JobStatus.expired:
        return 'expired';
    }
  }
}