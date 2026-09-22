import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../providers/saved_jobs_controller.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(savedJobsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: const EmptyState(message: 'No saved jobs yet'),
    );
  }
}
