import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/company_dashboard_controller.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(companyDashboardControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Company Dashboard')),
      body: const Center(child: Text('Company Dashboard')),
    );
  }
}
