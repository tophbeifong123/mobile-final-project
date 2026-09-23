import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              const _Pill(label: 'เครือข่ายมหาวิทยาลัยทั่วประเทศ'),
              const Gap(28),
              const AppLogo(size: 64),
              const Gap(24),
              Text('InternFinder', style: textTheme.headlineSmall),
              const Gap(8),
              Text(
                'ค้นหาที่ฝึกงานที่ใช่สำหรับคุณ',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(20),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(label: '#เด็กฝึกงาน'),
                  _Pill(label: 'สหกิจศึกษา'),
                  _Pill(label: 'ฝึกงานฤดูร้อน'),
                ],
              ),
              const Gap(28),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(minHeight: 6),
              ),
              const Gap(12),
              Text(
                'กำลังตรวจสอบการเข้าสู่ระบบ',
                style: textTheme.bodyMedium,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 16,
                    color: colors.mutedForeground,
                  ),
                  const Gap(6),
                  Text(
                    'ระบบความปลอดภัยระดับสถาบันการศึกษา',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
