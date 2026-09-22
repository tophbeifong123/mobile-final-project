import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../providers/jobs_controller.dart';
import '../widgets/job_filter_sheet.dart';

class JobFeedScreen extends ConsumerWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(jobsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home / Job Feed'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/student/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  return JobFilterSheet(
                    initial: filter,
                    onApply: (value) {
                      ref.read(jobsControllerProvider.notifier).apply(value);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: const EmptyState(message: 'No jobs yet'),
    );
  }
}
