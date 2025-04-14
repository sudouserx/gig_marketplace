import 'package:flutter/material.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/widgets/job_card.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';

class JobListingPage extends StatefulWidget {
  final bool isEmployer;

  const JobListingPage({Key? key, required this.isEmployer}) : super(key: key);

  @override
  _JobListingPageState createState() => _JobListingPageState();
}

class _JobListingPageState extends State<JobListingPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Job> _jobs = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  JobStatus? _selectedStatus;

  // Sample categories - in a real app, these would come from an API or database
  final List<String> _categories = [
    'All',
    'Design',
    'Development',
    'Marketing',
    'Writing',
    'Customer Service',
    'Virtual Assistant',
    'Data Entry',
    'Other'
  ];

  final List<String> _locations = [
    'All',
    'Remote',
    'New York',
    'London',
    'Tokyo',
    'Berlin',
    'Sydney',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // In a real app, you would call an API or service to get jobs
      // final jobs = await jobService.getJobs();
      
      // Mock delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));

    // Update the mockJobs list in the _loadJobs method
    final List<Job> mockJobs = [
      Job(
        id: '1',
        employerId: 'employer_1',
        title: 'UI/UX Designer Needed for Mobile App',
        description: 'We are looking for a talented UI/UX designer to help us design a mobile app for a fitness tracking platform.',
        category: 'Design',
        tags: ['UI', 'UX', 'Mobile', 'Fitness'],
        location: 'New York',
        isRemote: false,
        deadline: DateTime.now().add(const Duration(days: 14)),
        budget: 2500,
        status: JobStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 2)), // Changed from postedDate to createdAt
      ),
      Job(
        id: '2',
        employerId: 'employer_2',
        title: 'Frontend Developer for E-commerce Website',
        description: 'Looking for an experienced frontend developer to build a responsive e-commerce website using React.',
        category: 'Development',
        tags: ['React', 'Frontend', 'E-commerce'],
        location: '',
        isRemote: true,
        deadline: DateTime.now().add(const Duration(days: 30)),
        budget: 5000,
        status: JobStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 5)), // Changed from postedDate to createdAt
      ),
      Job(
        id: '3',
        employerId: 'employer_1',
        title: 'Content Writer for Blog Posts',
        description: 'Need a skilled content writer to create engaging blog posts on technology topics.',
        category: 'Writing',
        tags: ['Content', 'Blog', 'Technology'],
        location: 'London',
        isRemote: false,
        deadline: DateTime.now().add(const Duration(days: 7)),
        budget: 1000,
        status: JobStatus.filled,
        createdAt: DateTime.now().subtract(const Duration(days: 10)), // Changed from postedDate to createdAt
      ),
    ];

      setState(() {
        _jobs = mockJobs;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load jobs. Please try again.';
      });
    }
  }

  List<Job> get _filteredJobs {
    return _jobs.where((job) {
      // Filter by search query
      final matchesQuery = job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by category
      final matchesCategory = _selectedCategory == 'All' || job.category == _selectedCategory;

      // Filter by location
      final matchesLocation = _selectedLocation == 'All' ||
          (_selectedLocation == 'Remote' && job.isRemote) ||
          (!job.isRemote && job.location == _selectedLocation);

      // Filter by status
      final matchesStatus = _selectedStatus == null || job.status == _selectedStatus;

      return matchesQuery && matchesCategory && matchesLocation && matchesStatus;
    }).toList();
  }

  void _applyFilters() {
    // Close the filter sheet
    Navigator.pop(context);
    
    // Refresh UI with applied filters
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLocation = 'All';
      _selectedStatus = null;
    });
    Navigator.pop(context);
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      }
                    },
                  ),
                  if (widget.isEmployer) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<JobStatus?>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        const DropdownMenuItem(
                          value: JobStatus.active,
                          child: Text('Active'),
                        ),
                        const DropdownMenuItem(
                          value: JobStatus.filled,
                          child: Text('Filled'),
                        ),
                        const DropdownMenuItem(
                          value: JobStatus.expired,
                          child: Text('Expired'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Listings')),
        body: const LoadingIndicator(message: 'Loading jobs...'),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Listings')),
        body: ErrorDisplay(
          errorMessage: _errorMessage,
          onRetry: _loadJobs,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _filteredJobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your search or filters',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      return JobCard(
                        job: job,
                        isEmployer: widget.isEmployer,
                        onTap: () {
                          // Navigate to job detail page
                          Navigator.pushNamed(
                            context,
                            '/job-detail',
                            arguments: {
                              'job': job,
                              'isEmployer': widget.isEmployer,
                            },
                          );
                        },
                        onEdit: widget.isEmployer && job.employerId == 'employer_1' // Replace with current user id check
                            ? () {
                                // Navigate to edit job page
                                Navigator.pushNamed(
                                  context,
                                  '/create-job',
                                  arguments: job,
                                );
                              }
                            : null,
                        onDelete: widget.isEmployer && job.employerId == 'employer_1' // Replace with current user id check
                            ? () {
                                // Show delete confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Job'),
                                    content: const Text('Are you sure you want to delete this job?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Delete job (in a real app, call API)
                                          Navigator.pop(context);
                                          setState(() {
                                            _jobs.removeWhere((j) => j.id == job.id);
                                          });
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        onApply: !widget.isEmployer && job.status == JobStatus.active
                            ? () {
                                // Navigate to job application page or show application dialog
                                Navigator.pushNamed(
                                  context,
                                  '/job-detail',
                                  arguments: {
                                    'job': job,
                                    'isEmployer': widget.isEmployer,
                                    'showApplicationForm': true,
                                  },
                                );
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isEmployer
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to create job page
                Navigator.pushNamed(context, '/create-job');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}