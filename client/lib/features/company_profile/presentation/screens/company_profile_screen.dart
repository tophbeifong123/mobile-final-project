import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/company_profile_controller.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(companyProfileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: const Padding(
        padding: EdgeInsets.all(kPagePadding),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppHeroCard(
            title: 'โปรไฟล์บริษัท',
            body: 'ชื่อ โลโก้ ประเภทกิจการ และคำอธิบาย',
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('Logout'),
          ),
        ),
      ),
    );
  }
}
