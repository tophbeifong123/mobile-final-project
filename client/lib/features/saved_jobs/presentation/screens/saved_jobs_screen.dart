import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_heading.dart';
import '../providers/saved_jobs_controller.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(savedJobsControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'งานที่บันทึก',
                subtitle: 'งานที่กดบันทึกจากหน้ารายละเอียด',
              ),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.bookmark_outline,
                title: 'ยังไม่มีงานที่บันทึก',
                message: 'เปิดรายละเอียดงานแล้วกดบันทึก งานนั้นจะมาอยู่ที่นี่',
                action: AppPrimaryButton(
                  onPressed: () => context.go('/student/home'),
                  child: const Text('ไปหน้าแรก'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
