import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Auth Text Field with colored prefix icon badge
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.badgeColor,
    required this.badgeIcon,
    this.isRequired = false,
    this.helperText,
    this.onHelperTap,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final Color badgeColor;
  final IconData badgeIcon;
  final bool isRequired;
  final String? helperText;
  final VoidCallback? onHelperTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label Row with optional required asterisk and helper text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                  if (isRequired) ...[
                    const Gap(3),
                    const Text(
                      '*',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.errorBorder,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (helperText != null) ...[
              const Gap(8),
              Flexible(
                child: GestureDetector(
                  onTap: onHelperTap,
                  child: Text(
                    helperText!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: onHelperTap != null
                          ? NeoColors.electricIndigo
                          : NeoColors.subtleInk,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const Gap(6),
        // Input Box with Neo-Brutalist Hard Drop Shadow
        Container(
          decoration: BoxDecoration(
            color: NeoColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: NeoShadows.elevation2,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: NeoColors.inkSolid,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: NeoColors.pureWhite,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NeoColors.inkSolid,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      badgeIcon,
                      size: 18,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
                maxWidth: 48,
                maxHeight: 48,
              ),
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: NeoColors.mutedInk,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: NeoColors.inkSolid,
                  width: 2.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: NeoColors.inkSolid,
                  width: 2.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: NeoColors.inkSolid,
                  width: 2.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: NeoColors.errorBorder,
                  width: 2.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: NeoColors.errorBorder,
                  width: 2.5,
                ),
              ),
              errorStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: NeoColors.errorBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
