import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../providers/company_jobs_controller.dart';

class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(companyJobsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Jobs')),
      body: const EmptyState(message: 'No job posts yet'),
    );
  }
}
