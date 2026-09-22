import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_heading.dart';
import '../providers/applications_controller.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(applicationsControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'ใบสมัคร',
                subtitle: 'ชื่องาน บริษัท และสถานะล่าสุด',
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.assignment_outlined,
                title: 'ยังไม่มีใบสมัคร',
                message:
                    'สมัครจากหน้ารายละเอียดงาน ใบสมัครใหม่จะขึ้นสถานะ Submitted',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
