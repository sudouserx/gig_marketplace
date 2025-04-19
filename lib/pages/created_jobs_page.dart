import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/repositories/auth_repository.dart';
import 'package:gig_marketplace/repositories/job_repository.dart';
import 'package:gig_marketplace/services/api_service.dart';
import 'package:gig_marketplace/widgets/job_card.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/pages/create_job_page.dart';
import 'package:gig_marketplace/pages/job_detail_page.dart';

class CreatedJobsPage extends StatefulWidget {
  const CreatedJobsPage({Key? key}) : super(key: key);

  @override
  _CreatedJobsPageState createState() => _CreatedJobsPageState();
}

class _CreatedJobsPageState extends State<CreatedJobsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Job> _jobs = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  User? _currentUser;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
    _loadCurrentUser();

  }

      Future<void> _loadCurrentUser() async {
    try {
      final authRepository = RepositoryProvider.of<AuthRepository>(context);
      final user = await authRepository.getCurrentUser();
      
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
  
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // In a real app, you would call an API or service to get jobs
      final myApiService = ApiService();
      final jobRepository = JobRepository(apiService: myApiService);
      final jobs = await jobRepository.getEmployerJobs(
        employerId: _currentUser!.id, // Replace with actual user ID
      );

      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load your jobs. Please try again.';
      });
    }
  }

  List<Job> _getFilteredJobs(JobStatus status) {
    final searchQuery = _searchController.text.toLowerCase();
    return _jobs.where((job) {
      final matchesStatus = job.status == status;
      final matchesSearch = searchQuery.isEmpty ||
          job.title.toLowerCase().contains(searchQuery) ||
          job.description.toLowerCase().contains(searchQuery) ||
          job.category.toLowerCase().contains(searchQuery) ||
          job.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Job Postings'),
        ),
        body: const LoadingIndicator(message: 'Loading your job posts...'),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Job Postings'),
        ),
        body: ErrorDisplay(
          errorMessage: _errorMessage,
          onRetry: _loadJobs,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Postings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Filled'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(JobStatus.active),
                _buildJobList(JobStatus.filled),
                _buildJobList(JobStatus.expired),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create job page
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CreateJobPage()));
        },
        child: const Icon(Icons.add),
        tooltip: 'Create New Job',
      ),
    );
  }

  Widget _buildJobList(JobStatus status) {
    final filteredJobs = _getFilteredJobs(status);

    if (filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(status),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(status),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (status == JobStatus.active) ...[
              CustomButton(
                text: 'Post a New Job',
                icon: Icons.add,
                onPressed: () {
                  // Navigate to create job page
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJobPage()));
                },
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Colors.white,
                width: 200,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          final job = filteredJobs[index];
          return JobCard(
            job: job,
            isEmployer: true,
            onTap: () {
              // Navigate to job details
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailJobPage(jobId: job.jobId)));
            },
            onEdit: job.status != JobStatus.expired
                ? () {
                    // Navigate to edit job
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditJobPage(job: job)));
                  }
                : null,
            onDelete: () {
              _showDeleteConfirmation(job);
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Job job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Posting'),
        content: Text(
            'Are you sure you want to delete "${job.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(job.jobId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // In a real app, you would call an API to delete the job
      // await jobService.deleteJob(jobId);

      // Mock delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, just remove from the local list
      setState(() {
        _jobs.removeWhere((job) => job.jobId == jobId);
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Update state
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete job. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getEmptyStateIcon(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return Icons.add_task;
      case JobStatus.filled:
        return Icons.check_circle_outline;
      case JobStatus.expired:
        return Icons.timelapse;
    }
  }

  String _getEmptyStateMessage(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return 'You don\'t have any active job posts.\nCreate a new job posting to find talent.';
      case JobStatus.filled:
        return 'You don\'t have any filled positions yet.\nHire candidates from your active job posts.';
      case JobStatus.expired:
        return 'You don\'t have any expired job posts.';
    }
  }
}
