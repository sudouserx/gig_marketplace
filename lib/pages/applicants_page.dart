// lib/screens/applicants_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/bloc/application_bloc.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/models/job_application.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/profile_card.dart';

class ApplicantsPage extends StatefulWidget {
  final Job job;

  const ApplicantsPage({Key? key, required this.job}) : super(key: key);

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  String _sortCriteria = 'date';
  final TextEditingController _searchController = TextEditingController();
  List<JobApplication> _filteredApplicants = [];
  bool _isShortlistedOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<ApplicationBloc>().add(LoadJobApplicantsEvent(jobId: widget.job.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortApplicants(List<JobApplication> applicants) {
    switch (_sortCriteria) {
      case 'date':
        applicants.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        break;
      case 'name':
        applicants.sort((a, b) => a.employeeName.compareTo(b.employeeName));
        break;
      case 'rating':
        applicants.sort((a, b) {
          if (a.employeeRating == null && b.employeeRating == null) return 0;
          if (a.employeeRating == null) return 1;
          if (b.employeeRating == null) return -1;
          return b.employeeRating!.compareTo(a.employeeRating!);
        });
        break;
    }
  }

  void _filterApplicants(List<JobApplication> applicants, String query) {
    if (query.isEmpty && !_isShortlistedOnly) {
      _filteredApplicants = List.from(applicants);
    } else {
      _filteredApplicants = applicants.where((applicant) {
        bool matchesQuery = query.isEmpty || 
            applicant.employeeName.toLowerCase().contains(query.toLowerCase());
        bool matchesFilter = !_isShortlistedOnly || 
            applicant.status == ApplicationStatus.shortlisted;
        return matchesQuery && matchesFilter;
      }).toList();
    }
    _sortApplicants(_filteredApplicants);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants for ${widget.job.title}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Applicants',
            onSelected: (value) {
              setState(() {
                _sortCriteria = value;
                // Re-apply sorting to current filtered list
                _sortApplicants(_filteredApplicants);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Rating'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ApplicationBloc, ApplicationState>(
        listener: (context, state) {
          if (state is ApplicationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Reload applicants after status update
            context.read<ApplicationBloc>().add(LoadJobApplicantsEvent(jobId: widget.job.id));
          } else if (state is ApplicationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is ApplicationLoading) {
            return const LoadingIndicator(message: 'Loading applicants...');
          } else if (state is JobApplicantsLoaded) {
            final applicants = state.applicants;
            
            // Initialize filtered list if not already done
            if (_filteredApplicants.isEmpty) {
              _filteredApplicants = List.from(applicants);
              _sortApplicants(_filteredApplicants);
            }
            
            if (applicants.isEmpty) {
              return const Center(
                child: Text(
                  'No applicants yet for this job.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search applicants...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _filterApplicants(applicants, value);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('Shortlisted Only'),
                              selected: _isShortlistedOnly,
                              onSelected: (selected) {
                                setState(() {
                                  _isShortlistedOnly = selected;
                                  _filterApplicants(
                                    applicants,
                                    _searchController.text,
                                  );
                                });
                              },
                            ),
                          ),
                          Text(
                            '${_filteredApplicants.length}/${applicants.length} applicants',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredApplicants.length,
                    itemBuilder: (context, index) {
                      final applicant = _filteredApplicants[index];
                      return ProfileCard(
                        application: applicant,
                        onTap: () {
                          _showApplicantDetails(context, applicant);
                        },
                        onShortlist: applicant.status == ApplicationStatus.pending
                            ? () => _updateApplicationStatus(
                                  context,
                                  applicant.id,
                                  ApplicationStatus.shortlisted,
                                )
                            : null,
                        onReject: applicant.status != ApplicationStatus.rejected
                            ? () => _confirmReject(context, applicant)
                            : null,
                        onMessage: () {
                          // Navigate to messaging screen
                          Navigator.pushNamed(
                            context,
                            '/messaging',
                            arguments: {'userId': applicant.employeeId, 'name': applicant.employeeName},
                          );
                        },
                        onDownloadResume: applicant.resumeUrl != null
                            ? () => _downloadResume(applicant.resumeUrl!)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is ApplicationError) {
            return ErrorDisplay(
              errorMessage: state.message,
              onRetry: () {
                context.read<ApplicationBloc>().add(LoadJobApplicantsEvent(jobId: widget.job.id));
              },
            );
          } else {
            return const LoadingIndicator(message: 'Loading applicants...');
          }
        },
      ),
    );
  }

  void _updateApplicationStatus(
    BuildContext context,
    String applicationId,
    ApplicationStatus newStatus,
  ) {
    context.read<ApplicationBloc>().add(
          UpdateApplicationStatusEvent(
            applicationId: applicationId,
            newStatus: newStatus,
          ),
        );
  }

  void _confirmReject(BuildContext context, JobApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Applicant'),
        content: const Text(
          'Are you sure you want to reject this applicant? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateApplicationStatus(
                context,
                application.id,
                ApplicationStatus.rejected,
              );
            },
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadResume(String resumeUrl) {
    // Implement download functionality
    // This could open the resume in a web view or download it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading resume...')),
    );
  }

  void _showApplicantDetails(BuildContext context, JobApplication application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: application.employeeProfilePicture != null
                              ? NetworkImage(application.employeeProfilePicture!)
                              : null,
                          child: application.employeeProfilePicture == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.employeeName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (application.employeeRating != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      return Icon(
                                        index < (application.employeeRating ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${application.employeeRating!.toStringAsFixed(1)})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8), 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(application.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _getStatusColor(application.status)),
                                ),
                                child: Text(
                                  _getStatusText(application.status),
                                  style: TextStyle(
                                    color: _getStatusColor(application.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cover Letter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        application.coverLetter ?? 'No cover letter provided.',
                        style: TextStyle(
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Application Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTimeline(application),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        if (application.resumeUrl != null) ...[
                          Expanded(
                            child: CustomButton(
                              text: 'Download Resume',
                              icon: Icons.file_download,
                              backgroundColor: Colors.indigo,
                              onPressed: () => _downloadResume(application.resumeUrl!),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: CustomButton(
                            text: 'Message',
                            icon: Icons.message,
                            backgroundColor: Colors.green,
                            onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              Navigator.pushNamed(
                                context,
                                '/messaging',
                                arguments: {'userId': application.employeeId, 'name': application.employeeName},
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (application.status == ApplicationStatus.pending) ...[
                      CustomButton(
                        text: 'Shortlist Candidate',
                        icon: Icons.thumb_up,
                        backgroundColor: Colors.amber,
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          _updateApplicationStatus(
                            context,
                            application.id,
                            ApplicationStatus.shortlisted,
                          );
                        },
                      ),
                    ] else if (application.status == ApplicationStatus.shortlisted) ...[
                      CustomButton(
                        text: 'Hire Candidate',
                        icon: Icons.check_circle,
                        backgroundColor: Colors.green,
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          _updateApplicationStatus(
                            context,
                            application.id,
                            ApplicationStatus.hired,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (application.status != ApplicationStatus.rejected) ...[
                      CustomButton(
                        text: 'Reject Application',
                        icon: Icons.close,
                        backgroundColor: Colors.red,
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          _confirmReject(context, application);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeline(JobApplication application) {
    return Column(
      children: [
        _timelineItem(
          title: 'Applied',
          date: application.appliedAt,
          isActive: true,
          isFirst: true,
        ),
        _timelineItem(
          title: 'Shortlisted',
          date: null,
          isActive: application.status == ApplicationStatus.shortlisted || 
                   application.status == ApplicationStatus.hired,
        ),
        _timelineItem(
          title: 'Hired',
          date: null,
          isActive: application.status == ApplicationStatus.hired,
          isLast: true,
        ),
      ],
    );
  }

  Widget _timelineItem({
    required String title,
    required DateTime? date,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isActive ? Colors.blue : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
              if (date != null)
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.grey;
      case ApplicationStatus.shortlisted:
        return Colors.amber;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.hired:
        return Colors.green;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.hired:
        return 'Hired';
    }
  }
}