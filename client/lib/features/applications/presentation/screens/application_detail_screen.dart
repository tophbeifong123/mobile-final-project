import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';

class ApplicationDetailScreen extends StatelessWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Detail')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Application Detail: $applicationId'),
            const SizedBox(height: 12),
            const StatusChip(label: 'Submitted'),
          ],
        ),
      ),
    );
  }
}
