import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../providers/applications_controller.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(applicationsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: const EmptyState(message: 'No applications yet'),
    );
  }
}
