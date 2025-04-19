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
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<JobBloc, JobState>(
        builder: (context, state) {
          if (state is JobLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is JobError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadJobDetails,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildJobHeader(job, isEmployer),
        ),
        SliverToBoxAdapter(
          child: _buildJobBody(job),
        ),
        if (job.mediaUrls != null && job.mediaUrls!.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildAttachments(job.mediaUrls!),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            alignment: Alignment.bottomCenter,
            child: _buildJobActions(context, job, isEmployer, authState),
          ),
        ),
      ],
    );
  }

  Widget _buildJobHeader(Job job, bool isEmployer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusChip(job.status),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoItem(
            Icons.business_center_rounded,
            job.category,
            Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            job.isRemote ? Icons.language_rounded : Icons.location_on_rounded,
            job.isRemote ? 'Remote' : job.location,
            Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.event_rounded,
            'Deadline: ${DateFormat('MMM dd, yyyy').format(job.deadline)}',
            Colors.white.withOpacity(0.9),
          ),
          if (job.budget != null) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.payments_rounded,
              'Budget: \$${job.budget!.toStringAsFixed(2)}',
              Colors.white.withOpacity(0.9),
            ),
          ],
          if (isEmployer) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.people_alt_rounded,
              'Applicants: ${job.applicants!.length}',
              Colors.white.withOpacity(0.9),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildJobBody(Job job) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.tag_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Skills & Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Posted on: ${DateFormat('MMM dd, yyyy').format(job.createdAt)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(List<String> mediaUrls) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mediaUrls.length,
                itemBuilder: (context, index) {
                  final url = mediaUrls[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
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
      ),
    );
  }

  Widget _buildAttachmentPreview(String url) {
    if (url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
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
            return const Icon(Icons.broken_image_rounded, size: 36);
          },
        ),
      );
    } else if (url.endsWith('.pdf')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 38),
          const SizedBox(height: 8),
          Text(
            'PDF Document',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    } else if (url.endsWith('.doc') || url.endsWith('.docx')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_rounded, color: Colors.blue, size: 38),
          const SizedBox(height: 8),
          Text(
            'Word Document',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_rounded, color: Colors.grey.shade700, size: 38),
          const SizedBox(height: 8),
          Text(
            'File',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildJobActions(BuildContext context, Job job, bool isEmployer, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                          arguments: job.jobId,
                        ).then((_) => _loadJobDetails());
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                          arguments: job.jobId,
                        );
                      },
                      icon: const Icon(Icons.people_alt_rounded),
                      label: Text('Applicants (${job.applicants!.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Show delete confirmation
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Job'),
                      content: const Text('Are you sure you want to delete this job posting?'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<JobBloc>().add(DeleteJobEvent(jobId: job.jobId));
                            Navigator.pop(context); // Go back to jobs list
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  elevation: 0,
                ),
              ),
            ] else if (authState is AuthAuthenticated && authState.user.role == UserRole.employee) ...[
              // Employee actions
              ElevatedButton.icon(
                onPressed: job.status == JobStatus.active
                    ? () {
                        // Show apply dialog
                        _showApplyDialog(context, job, (authState as AuthAuthenticated).user);
                      }
                    : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  job.status == JobStatus.active
                      ? 'Apply Now'
                      : job.status == JobStatus.filled
                          ? 'This Position Has Been Filled'
                          : 'This Posting Has Expired',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to employer profile
                  Navigator.pushNamed(
                    context,
                    '/employer-profile',
                    arguments: job.employerId,
                  );
                },
                icon: const Icon(Icons.business_center_rounded),
                label: const Text('View Employer Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ] else ...[
              // Unauthenticated user
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign In to Apply', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, Job job, User currentUser) {
    final coverLetterController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.work_rounded, 
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('Apply for Job'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'You are applying for: ${job.title}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),
              if (currentUser.resumeUrl == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You don\'t have a resume uploaded to your profile. '
                          'It\'s recommended to add a resume before applying.',
                          style: TextStyle(color: Colors.orange[800], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.grey[700], size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Cover Letter (Optional):',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: coverLetterController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write a brief message to the employer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              
              // Submit application
              context.read<ApplicationBloc>().add(
                ApplyForJobEvent(
                  jobId: job.jobId,
                  employeeId: currentUser.id,
                  coverLetter: coverLetterController.text.trim(),
                ),
              );
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Application submitted successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(8),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Submit Application'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case JobStatus.active:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[700]!;
        text = 'Active';
        icon = Icons.check_circle_rounded;
        break;
      case JobStatus.filled:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue[700]!;
        text = 'Filled';
        icon = Icons.person_search_rounded;
        break;
      case JobStatus.expired:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red[700]!;
        text = 'Expired';
        icon = Icons.timer_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}