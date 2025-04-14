import 'package:flutter/material.dart';
import 'package:gig_marketplace/models/job_application.dart';

class ApplicationStatusChip extends StatelessWidget {
  final ApplicationStatus status;
  final double fontSize;

  const ApplicationStatusChip({
    Key? key,
    required this.status,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          fontSize: fontSize,
        ),
      ),
    );
  }
}