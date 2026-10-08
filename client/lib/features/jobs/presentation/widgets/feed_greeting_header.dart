import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';

/// Shared student profile header for Home and My Applications.
class FeedGreetingHeader extends ConsumerWidget {
  const FeedGreetingHeader({
    super.key,
    this.name,
    this.university,
    this.major,
    this.avatarKey,
    this.showMajor = false,
  });

  final String? name;
  final String? university;
  final String? major;
  final String? avatarKey;
  final bool showMajor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = name?.trim() ?? '';
    final displayUniversity = university?.trim() ?? '';
    final displayMajor = major?.trim() ?? '';
    final avatar = avatarKey?.trim() ?? '';
    final avatarBytes = avatar.isEmpty
        ? null
        : ref.watch(studentAvatarBytesProvider(avatar)).asData?.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // No fabricated online/completeness status on the profile avatar.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: avatarBytes == null || avatarBytes.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: NeoColors.inkSolid,
                        )
                      : Image.memory(
                          Uint8List.fromList(avatarBytes),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: NeoColors.inkSolid,
                              ),
                        ),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Greeting & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'สวัสดี',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (displayName.isNotEmpty) ...[
                      const Gap(4),
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.inkSolid,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                    const Gap(4),
                    const Text('✨', style: TextStyle(fontSize: 16)),
                  ],
                ),
                if (displayUniversity.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    displayUniversity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: NeoColors.subtleInk,
                    ),
                  ),
                ],
                if (showMajor && displayMajor.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    displayMajor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: NeoColors.subtleInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
