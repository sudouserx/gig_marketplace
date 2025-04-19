import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/models/user.dart';
import 'package:gig_marketplace/repositories/auth_repository.dart';
import 'package:gig_marketplace/repositories/job_repository.dart';
import 'package:gig_marketplace/services/api_service.dart';
import 'package:gig_marketplace/widgets/custom_button.dart';
import 'package:gig_marketplace/widgets/form_container.dart';
import 'package:gig_marketplace/widgets/input_field.dart';
import 'package:gig_marketplace/widgets/loading_indicator.dart';
import 'package:gig_marketplace/widgets/error_display.dart';
import 'package:intl/intl.dart';

class CreateJobPage extends StatefulWidget {
  final Job? jobToEdit;

  const CreateJobPage({Key? key, this.jobToEdit}) : super(key: key);

  @override
  _CreateJobPageState createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  DateTime? _deadline;
  String _selectedCategory = 'Design';
  bool _isRemote = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<String> _tags = [];
  User? _currentUser;


  // Sample categories - in a real app, these would come from an API or database
  final List<String> _categories = [
    'Design',
    'Development',
    'Marketing',
    'Writing',
    'Customer Service',
    'Virtual Assistant',
    'Data Entry',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    
    if (widget.jobToEdit != null) {
      // Pre-fill form fields if we're editing an existing job
      _titleController.text = widget.jobToEdit!.title;
      _descriptionController.text = widget.jobToEdit!.description;
      _locationController.text = widget.jobToEdit!.location;
      if (widget.jobToEdit!.budget != null) {
        _budgetController.text = widget.jobToEdit!.budget.toString();
      }
      _deadline = widget.jobToEdit!.deadline;
      _selectedCategory = widget.jobToEdit!.category;
      _isRemote = widget.jobToEdit!.isRemote;
      _tags = List<String>.from(widget.jobToEdit!.tags);
      _tagsController.text = _tags.join(', ');
    }
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _updateTags(String value) {
    setState(() {
      _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    });
  }

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) {
      if (_deadline == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please select a deadline for the job.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      try {

        String currentUserId = _currentUser!.id;

        // Create job object - updated to match the Job model
        final job = Job(
          jobId: widget.jobToEdit?.jobId ?? 'new_job_id',
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          location: _locationController.text,
          isRemote: _isRemote,
          deadline: _deadline!,
          budget: _budgetController.text.isNotEmpty ? double.parse(_budgetController.text) : null,
          tags: _tags,
          status: widget.jobToEdit?.status ?? JobStatus.active,
          createdAt: widget.jobToEdit?.createdAt ?? DateTime.now(),
          employerId: widget.jobToEdit?.employerId ?? currentUserId, // Use actual user ID
          // Include additional fields that might be needed
          mediaUrls: widget.jobToEdit?.mediaUrls ?? [],
          applicants: widget.jobToEdit?.applicants ?? [],
        );

        // In a real app, you would save this to your backend
        final myApiService = ApiService();
        final jobRepository = JobRepository(apiService: myApiService);
        
        if (widget.jobToEdit != null) {
          // Update existing job
          await jobRepository.updateJob(
            jobId: job.jobId,
            title: job.title,
            description: job.description,
            category: job.category,
            tags: job.tags,
            location: job.location,
            isRemote: job.isRemote,
            deadline: job.deadline,
            budget: job.budget,
          );
        } else {
          // Create new job
          await jobRepository.createJob(
            employerId: job.employerId,
            title: job.title,
            description: job.description,
            category: job.category,
            tags: job.tags,
            location: job.location,
            isRemote: job.isRemote,
            deadline: job.deadline,
            budget: job.budget,
          );
        }

        if (mounted) {
          // Return the created/updated job to the previous screen
          Navigator.pop(context, job);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.jobToEdit != null ? 'Job updated successfully' : 'Job created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = error.toString().contains('User not authenticated') 
                ? 'You must be logged in to create a job' 
                : 'Failed to submit job. Please try again.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.jobToEdit != null ? 'Update Job' : 'Create Job')),
        body: const LoadingIndicator(message: 'Submitting job...'),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.jobToEdit != null ? 'Update Job' : 'Create Job')),
        body: ErrorDisplay(
          errorMessage: _errorMessage,
          onRetry: () {
            setState(() {
              _hasError = false;
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.jobToEdit != null ? 'Update Job' : 'Create Job')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormContainer(
                  title: 'Job Details',
                  children: [
                    InputField(
                      label: 'Job Title',
                      controller: _titleController,
                      isRequired: true,
                      prefixIcon: Icons.work,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a job title';
                        }
                        if (value.length < 5) {
                          return 'Job title should be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    
                    InputField(
                      label: 'Job Description',
                      controller: _descriptionController,
                      isRequired: true,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      prefixIcon: Icons.description,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a job description';
                        }
                        if (value.length < 20) {
                          return 'Please provide a more detailed description (at least 20 characters)';
                        }
                        return null;
                      },
                    ),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _selectedCategory,
                      items: _categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    InputField(
                      label: 'Tags/Keywords (comma separated)',
                      controller: _tagsController,
                      prefixIcon: Icons.tag,
                      onChanged: _updateTags,
                      // helperText: 'Add relevant skills or keywords to help freelancers find your job',
                    ),
                    
                    if (_tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _tags.map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                                _tagsController.text = _tags.join(', ');
                              });
                            },
                          )).toList(),
                        ),
                      ),
                  ],
                ),
                
                FormContainer(
                  title: 'Location & Schedule',
                  children: [
                    SwitchListTile(
                      title: const Text('Remote Job'),
                      subtitle: Text(_isRemote ? 'Work can be done from anywhere' : 'On-site work required'),
                      value: _isRemote,
                      onChanged: (bool value) {
                        setState(() {
                          _isRemote = value;
                        });
                      },
                    ),
                    
                    if (!_isRemote)
                      InputField(
                        label: 'Location',
                        controller: _locationController,
                        isRequired: true,
                        prefixIcon: Icons.location_on,
                        validator: (value) {
                          if (!_isRemote && (value == null || value.isEmpty)) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),
                    
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Deadline *'),
                      subtitle: Text(
                        _deadline != null
                            ? DateFormat('MMMM dd, yyyy').format(_deadline!)
                            : 'Select a date',
                        style: TextStyle(
                          color: _deadline == null ? Colors.red : null,
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      trailing: _deadline != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _deadline = null;
                                });
                              },
                            )
                          : null,
                    ),
                  ],
                ),
                
                FormContainer(
                  title: 'Payment Details',
                  children: [
                    InputField(
                      label: 'Budget (optional)',
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.attach_money,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final number = double.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          if (number <= 0) {
                            return 'Budget must be greater than zero';
                          }
                        }
                        return null;
                      },
                      // helperText: 'Enter the maximum amount you\'re willing to pay for this job',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                CustomButton(
                  text: widget.jobToEdit != null ? 'Update Job' : 'Publish Job',
                  onPressed: _submitJob,
                  icon: widget.jobToEdit != null ? Icons.update : Icons.publish,
                  backgroundColor: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}