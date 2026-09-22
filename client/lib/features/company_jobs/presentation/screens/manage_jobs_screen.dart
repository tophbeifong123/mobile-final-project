import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_heading.dart';
import '../providers/company_jobs_controller.dart';

class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(companyJobsControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'ประกาศของบริษัท',
                subtitle: 'สร้างประกาศใหม่ได้จากปุ่มด้านล่าง',
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.work_outline,
                title: 'ยังไม่มีประกาศ',
                message: 'ประกาศใหม่จะเริ่มที่สถานะ Open',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kPagePadding,
                8,
                kPagePadding,
                16,
              ),
              child: AppPrimaryButton(
                onPressed: () => context.push('/company/jobs/new'),
                child: const Text('สร้างประกาศ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
