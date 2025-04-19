// lib/widgets/job_card.dart
import 'package:flutter/material.dart';
import 'package:gig_marketplace/models/job.dart';
import 'package:intl/intl.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApply;
  final bool isEmployer;

  const JobCard({
    Key? key,
    required this.job,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onApply,
    required this.isEmployer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getCategoryColor(job.category).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(job.category),
                    size: 16,
                    color: _getCategoryColor(job.category),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    job.category,
                    style: TextStyle(
                      color: _getCategoryColor(job.category),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(job.status),
                ],
              ),
            ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    job.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Job details - top row
                  Row(
                    children: [
                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                job.isRemote ? Icons.public : Icons.location_on,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    job.isRemote ? 'Remote' : job.location,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Budget
                      if (job.budget != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  size: 20,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Budget',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      NumberFormat.currency(
                                        symbol: '\$',
                                        decimalDigits: 0,
                                      ).format(job.budget),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Deadline
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 20,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deadline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.formattedDeadline,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEmployer && onEdit != null) ...[
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ],
                  if (isEmployer && onDelete != null) ...[
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                      ),
                    ),
                  ],
                  if (!isEmployer && onApply != null && job.status == JobStatus.active) ...[
                    ElevatedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.send),
                      label: const Text('Apply Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case JobStatus.active:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        text = 'Active';
        break;
      case JobStatus.filled:
        color = Colors.blue;
        icon = Icons.people_outline;
        text = 'Filled';
        break;
      case JobStatus.expired:
        color = Colors.red;
        icon = Icons.timer_off_outlined;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    // Add more categories as needed
    switch (category.toLowerCase()) {
      case 'design':
        return Icons.palette_outlined;
      case 'development':
        return Icons.code;
      case 'marketing':
        return Icons.campaign_outlined;
      case 'writing':
        return Icons.article_outlined;
      case 'data':
        return Icons.analytics_outlined;
      case 'customer service':
        return Icons.support_agent_outlined;
      case 'administration':
        return Icons.business_center_outlined;
      default:
        return Icons.work_outline;
    }
  }
  
  Color _getCategoryColor(String category) {
    // Add more categories as needed
    switch (category.toLowerCase()) {
      case 'design':
        return Colors.purple;
      case 'development':
        return Colors.blue;
      case 'marketing':
        return Colors.orange;
      case 'writing':
        return Colors.teal;
      case 'data':
        return Colors.indigo;
      case 'customer service':
        return Colors.green;
      case 'administration':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}