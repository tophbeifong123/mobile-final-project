import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';

class ApplicantDetailScreen extends StatelessWidget {
  const ApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.applicationId,
  });

  final String jobId;
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicant Detail')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Applicant Detail: $jobId / $applicationId'),
            const SizedBox(height: 12),
            const StatusChip(label: 'Submitted'),
          ],
        ),
      ),
    );
  }
}
