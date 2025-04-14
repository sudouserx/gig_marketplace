// lib/screens/detail_job_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gig_marketplace/bloc/application_bloc.dart';
import 'package:gig_marketplace/bloc/job_bloc.dart';
import 'package:gig_marketplace/bloc/auth_bloc.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:gig_marketplace/models/user.dart';

class DetailJobPage extends StatefulWidget {
  final String jobId;
  final bool isFromEmployerDashboard;

  const DetailJobPage({
    Key? key,
    required this.jobId,
    this.isFromEmployerDashboard = false,
  }) : super(key: key);

  @override
  State<DetailJobPage> createState() => _DetailJobPageState();
}

class _DetailJobPageState extends State<DetailJobPage> {
  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  void _loadJobDetails() {
    context.read<JobBloc>().add(LoadJobDetailsEvent(jobId: widget.jobId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<JobBloc, JobState>(
        builder: (context, state) {
          if (state is JobLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is JobError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadJobDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is JobDetailsLoaded) {
            return _buildJobDetails(context, state.job);
          }
          return const Center(child: Text('No job details available'));
        },
      ),
    );
  }

  Widget _buildJobDetails(BuildContext context, Job job) {
    final authState = context.watch<AuthBloc>().state;
    final isEmployer = authState is AuthAuthenticated && 
                        authState.user.role == UserRole.employer &&
                        authState.user.id == job.employerId;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeader(job, isEmployer),
          _buildJobBody(job),
          if (job.mediaUrls != null && job.mediaUrls!.isNotEmpty)
            _buildAttachments(job.mediaUrls!),
          _buildJobActions(context, job, isEmployer, authState),
        ],
      ),
    );
  }

  Widget _buildJobHeader(Job job, bool isEmployer) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusChip(job.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.category, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                job.category,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                job.isRemote ? 'Remote' : job.location,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                'Deadline: ${DateFormat('MMM dd, yyyy').format(job.deadline)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (job.budget != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Budget: \$${job.budget!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (isEmployer) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Applicants: ${job.applicantCount}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobBody(Job job) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Posted on: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(DateFormat('MMM dd, yyyy').format(job.createdAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<String> mediaUrls) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaUrls.length,
              itemBuilder: (context, index) {
                final url = mediaUrls[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Handle attachment view/download
                    },
                    child: Center(
                      child: _buildAttachmentPreview(url),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(String url) {
    if (url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
      );
    } else if (url.endsWith('.pdf')) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(height: 4),
          Text('PDF', style: TextStyle(fontSize: 12)),
        ],
      );
    } else if (url.endsWith('.doc') || url.endsWith('.docx')) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, color: Colors.blue),
          SizedBox(height: 4),
          Text('DOC', style: TextStyle(fontSize: 12)),
        ],
      );
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attachment),
          SizedBox(height: 4),
          Text('File', style: TextStyle(fontSize: 12)),
        ],
      );
    }
  }

  Widget _buildJobActions(BuildContext context, Job job, bool isEmployer, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEmployer) ...[
            // Employer actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: job.status == JobStatus.expired ? null : () {
                      // Navigate to edit job page
                      Navigator.pushNamed(
                        context,
                        '/edit-job',
                        arguments: job.id,
                      ).then((_) => _loadJobDetails());
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to applicants list
                      Navigator.pushNamed(
                        context,
                        '/job-applicants',
                        arguments: job.id,
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: Text('View Applicants (${job.applicantCount})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Show delete confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Job'),
                    content: const Text('Are you sure you want to delete this job posting?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<JobBloc>().add(DeleteJobEvent(jobId: job.id));
                          Navigator.pop(context); // Go back to jobs list
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ] else if (authState is AuthAuthenticated && authState.user.role == UserRole.employee) ...[
            // Employee actions
            ElevatedButton(
              onPressed: job.status == JobStatus.active
                  ? () {
                      // Show apply dialog
                      _showApplyDialog(context, job, (authState as AuthAuthenticated).user);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                job.status == JobStatus.active
                    ? 'Apply Now'
                    : job.status == JobStatus.filled
                        ? 'This Position Has Been Filled'
                        : 'This Posting Has Expired',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to employer profile
                Navigator.pushNamed(
                  context,
                  '/employer-profile',
                  arguments: job.employerId,
                );
              },
              icon: const Icon(Icons.business),
              label: const Text('View Employer Profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ] else ...[
            // Unauthenticated user
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign In to Apply', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context, Job job, User currentUser) {
    final coverLetterController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are applying for: ${job.title}'),
              const SizedBox(height: 16),
              if (currentUser.resumeUrl == null) ...[
                const Text(
                  'Note: You don\'t have a resume uploaded to your profile. '
                  'It\'s recommended to add a resume before applying.',
                  style: TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Cover Letter (Optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: coverLetterController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write a brief message to the employer...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Submit application
              context.read<ApplicationBloc>().add(
                ApplyForJobEvent(
                  jobId: job.id,
                  employeeId: currentUser.id,
                  coverLetter: coverLetterController.text.trim(),
                ),
              );
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    String text;

    switch (status) {
      case JobStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case JobStatus.filled:
        color = Colors.blue;
        text = 'Filled';
        break;
      case JobStatus.expired:
        color = Colors.red;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 12,
        ),
      ),
    );
  }
}