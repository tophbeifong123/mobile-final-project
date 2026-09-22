import 'package:flutter/material.dart';

class ApplyJobScreen extends StatelessWidget {
  const ApplyJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Job')),
      body: Center(child: Text('Apply Job: $jobId')),
    );
  }
}
