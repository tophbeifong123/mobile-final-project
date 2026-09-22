import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_controller.dart';

class ResumeUploadScreen extends ConsumerWidget {
  const ResumeUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(resumeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Upload')),
      body: const Center(child: Text('Resume Upload')),
    );
  }
}
