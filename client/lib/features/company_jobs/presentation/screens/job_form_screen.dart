import 'package:flutter/material.dart';

class JobFormScreen extends StatelessWidget {
  const JobFormScreen({super.key, this.jobId});

  final String? jobId;

  @override
  Widget build(BuildContext context) {
    final title = jobId == null ? 'Create Job' : 'Edit Job';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
