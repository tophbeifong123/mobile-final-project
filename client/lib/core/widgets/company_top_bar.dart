import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';

/// The shared company header. Notifications belong to the student experience.
class CompanyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CompanyTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.backLocation = '/company/jobs',
  });

  final String title;
  final bool showBack;
  final String backLocation;

  static const double _height = 72;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(backLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: _height,
      titleSpacing: kPagePadding,
      backgroundColor: NeoColors.paperCanvas,
      foregroundColor: NeoColors.inkSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: NeoColors.inkSolid, width: 2),
      ),
      leadingWidth: showBack ? 56 : null,
      leading: showBack
          ? IconButton(
              key: const Key('company-top-bar-back'),
              tooltip: 'กลับ',
              onPressed: () => _goBack(context),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NeoColors.butterYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
              boxShadow: NeoShadows.elevation1,
            ),
            child: const ExcludeSemantics(
              child: Icon(Icons.business_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'InternMatch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: kPagePadding),
          child: Center(
            child: Semantics(
              label: 'ฝั่งบริษัท',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: const Text(
                  'บริษัท',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
