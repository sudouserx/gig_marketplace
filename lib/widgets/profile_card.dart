import 'package:flutter/material.dart';
import 'package:gig_marketplace/models/job_application.dart';

class ProfileCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;
  final VoidCallback? onShortlist;
  final VoidCallback? onReject;
  final VoidCallback? onMessage;
  final VoidCallback? onDownloadResume;

  const ProfileCard({
    Key? key,
    required this.application,
    required this.onTap,
    this.onShortlist,
    this.onReject,
    this.onMessage,
    this.onDownloadResume,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: application.employeeProfilePicture != null
                        ? NetworkImage(application.employeeProfilePicture!)
                        : null,
                    child: application.employeeProfilePicture == null
                        ? const Icon(Icons.person)
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRatingStars(application.employeeRating),
                            const SizedBox(width: 8),
                            if (application.employeeRating != null)
                              Text(
                                '(${application.employeeRating!.toStringAsFixed(1)})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(application.status),
                ],
              ),
              if (application.coverLetter != null && application.coverLetter!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Cover Letter:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  application.coverLetter!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDownloadResume != null && application.resumeUrl != null) ...[
                    IconButton(
                      onPressed: onDownloadResume,
                      icon: const Icon(Icons.file_download, color: Colors.blue),
                      tooltip: 'Download Resume',
                    ),
                  ],
                  if (onMessage != null) ...[
                    IconButton(
                      onPressed: onMessage,
                      icon: const Icon(Icons.message, color: Colors.green),
                      tooltip: 'Message',
                    ),
                  ],
                  if (onShortlist != null && application.status == ApplicationStatus.pending) ...[
                    ElevatedButton(
                      onPressed: onShortlist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      child: const Text('Shortlist'),
                    ),
                  ],
                  if (onReject != null && 
                      (application.status == ApplicationStatus.pending || 
                       application.status == ApplicationStatus.shortlisted)) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double? rating) {
    if (rating == null) return const SizedBox();

    return Row(
      children: List.generate(5, (index) {
        Icon starIcon;
        if (index < rating) {
          starIcon = Icon(
            Icons.star,
            color: Colors.amber,
            size: 16,
          );
        } else {
          starIcon = Icon(
            Icons.star_border,
            color: Colors.amber,
            size: 16,
          );
        }
        return starIcon;
      }),
    );
  }
  Widget _buildStatusChip(ApplicationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.grey;
        text = 'Pending';
        break;
      case ApplicationStatus.shortlisted:
        color = Colors.amber;
        text = 'Shortlisted';
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case ApplicationStatus.hired:
        color = Colors.green;
        text = 'Hired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
}