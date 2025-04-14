import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/bloc/application_bloc.dart';
import 'package:gig_marketplace/models/job_application.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/application_status_chip.dart';
import 'package:intl/intl.dart';

class AppliedJobsPage extends StatefulWidget {
  final User currentUser;

  const AppliedJobsPage({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AppliedJobsPage> createState() => _AppliedJobsPageState();
}

class _AppliedJobsPageState extends State<AppliedJobsPage> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'Shortlisted', 'Rejected', 'Hired'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ApplicationBloc>().add(
          LoadAppliedJobsEvent(employeeId: widget.currentUser.id),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JobApplication> _filterApplications(List<JobApplication> applications) {
    return applications.where((application) {
      // Filter by search query - using job ID since we don't have jobTitle
      final matchesQuery = application.jobId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          application.employeeName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by status
      final matchesStatus = _statusFilter == 'All' ||
          application.status.toString().split('.').last.toLowerCase() == _statusFilter.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: BlocBuilder<ApplicationBloc, ApplicationState>(
              builder: (context, state) {
                if (state is ApplicationLoading) {
                  return const LoadingIndicator(message: 'Loading your applications...');
                } else if (state is AppliedJobsLoaded) {
                  final filteredApplications = _filterApplications(state.applications);
                  return filteredApplications.isEmpty
                      ? _buildEmptyState()
                      : _buildApplicationsList(filteredApplications);
                } else if (state is ApplicationError) {
                  return ErrorDisplay(
                    errorMessage: state.message,
                    onRetry: () => context.read<ApplicationBloc>().add(
                          LoadAppliedJobsEvent(employeeId: widget.currentUser.id),
                        ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search jobs...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Status Filter Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                icon: const Icon(Icons.filter_list),
                isExpanded: true,
                hint: const Text('Filter by status'),
                items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _statusFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'All'
                ? 'No matching applications found'
                : 'You haven\'t applied to any jobs yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty && _statusFilter == 'All')
            CustomButton(
              text: 'Browse Available Jobs',
              onPressed: () {
                // Navigate to job listing page
                Navigator.pushNamed(context, '/jobs');
              },
              backgroundColor: Theme.of(context).primaryColor,
              width: 200,
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(List<JobApplication> applications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return _buildApplicationCard(application);
      },
    );
  }

  Widget _buildApplicationCard(JobApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to application details
          Navigator.pushNamed(
            context,
            '/application-details',
            arguments: application,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder(
                      // Assume we have a service to fetch job details by ID
                      future: context.read<JobService>().getJobById(application.jobId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return Text(
                          'Job ID: ${application.jobId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  ApplicationStatusChip(status: application.status),
                ],
              ),
              const SizedBox(height: 8),
              // Your Profile Information (since it's the employee's applications)
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: application.employeeProfilePicture != null
                        ? NetworkImage(application.employeeProfilePicture!)
                        : null,
                    child: application.employeeProfilePicture == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    application.employeeName,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (application.employeeRating != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(
                          application.employeeRating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Application Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Applied: ${DateFormat('MMM d, yyyy').format(application.appliedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (application.resumeUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Resume attached',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (application.coverLetter != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.article, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Cover letter included',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusActionButton(application),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to job details
                      Navigator.pushNamed(
                        context,
                        '/job-details',
                        arguments: application.jobId,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: const Text('View Job'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusActionButton(JobApplication application) {
    // Different actions based on application status
    switch (application.status) {
      case ApplicationStatus.pending:
        return OutlinedButton(
          onPressed: () {
            // Message the employer
            _navigateToMessageEmployer(application);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue),
          ),
          child: const Text('Message Employer'),
        );
      case ApplicationStatus.shortlisted:
        return ElevatedButton(
          onPressed: () {
            // Schedule an interview or message employer
            _showScheduleInterviewOptions(application);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
          ),
          child: const Text('Schedule Interview'),
        );
      case ApplicationStatus.rejected:
        return OutlinedButton(
          onPressed: () {
            // View similar jobs
            Navigator.pushNamed(
              context,
              '/similar-jobs',
              arguments: {'jobId': application.jobId},
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
          ),
          child: const Text('Find Similar Jobs'),
        );
      case ApplicationStatus.hired:
        return ElevatedButton(
          onPressed: () {
            // View job details or contract
            _showHiredOptions(application);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('View Contract'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _navigateToMessageEmployer(JobApplication application) {
    // We need to fetch the employer ID from the job details
    // For now, assume we have a way to get employerId from jobId
    _getEmployerIdFromJobId(application.jobId).then((employerId) {
      if (employerId != null) {
        Navigator.pushNamed(
          context,
          '/messages',
          arguments: {
            'receiverId': employerId,
            'receiverName': 'Employer', // This would come from job details
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find employer information')),
        );
      }
    });
  }

  Future<String?> _getEmployerIdFromJobId(String jobId) async {
    // In a real app, this would be a call to your job service
    // For now, we'll just return a placeholder
    return Future.value('employer-id');
  }

  void _showScheduleInterviewOptions(JobApplication application) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You\'ve been shortlisted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The employer is interested in your profile. You can suggest interview times or message them directly.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Suggest Interview Times',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/schedule-interview',
                    arguments: application,
                  );
                },
                backgroundColor: Colors.amber,
                icon: Icons.schedule,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Message Employer',
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToMessageEmployer(application);
                },
                backgroundColor: Colors.blue,
                icon: Icons.message,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHiredOptions(JobApplication application) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ve been hired for this job. View contract details or message the employer.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'View Contract Details',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/contract-details',
                    arguments: application,
                  );
                },
                backgroundColor: Colors.green,
                icon: Icons.description,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Message Employer',
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToMessageEmployer(application);
                },
                backgroundColor: Colors.blue,
                icon: Icons.message,
              ),
            ],
          ),
        );
      },
    );
  }
}

// This is a placeholder class - you would need to implement this service
class JobService {
  Future<Job> getJobById(String id) async {
    // In a real app, this would fetch job details from your API
    return Future.value(Job(id: id, title: 'Job Title'));
  }
}

class Job {
  final String id;
  final String title;
  
  Job({required this.id, required this.title});
}