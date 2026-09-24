import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/auth_session.dart';

/// Reusable Neo-Brutalist Segmented Switcher for selecting UserRole
class RoleSegmentedToggle extends StatelessWidget {
  const RoleSegmentedToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.enabled = true,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole>? onRoleChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NeoColors.inkSolid,
          width: 2.2,
        ),
      ),
      child: Row(
        children: [
          // Student Option
          Expanded(
            child: _RoleTabItem(
              label: 'นักศึกษา',
              icon: Icons.school_rounded,
              isSelected: selectedRole == UserRole.student,
              onTap: enabled && onRoleChanged != null
                  ? () => onRoleChanged!(UserRole.student)
                  : null,
            ),
          ),
          // Company Option
          Expanded(
            child: _RoleTabItem(
              label: 'บริษัท / องค์กร',
              icon: Icons.apartment_rounded,
              isSelected: selectedRole == UserRole.company,
              onTap: enabled && onRoleChanged != null
                  ? () => onRoleChanged!(UserRole.company)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTabItem extends StatelessWidget {
  const _RoleTabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.butterYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: NeoColors.inkSolid, width: 1.8)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: NeoColors.inkSolid,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: NeoColors.inkSolid,
            ),
            const Gap(6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: NeoColors.inkSolid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
