import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Social Authentication Button
class AuthSocialButton extends StatefulWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
    this.busy = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  /// Shows the pressed look when pointer input is handled outside Flutter,
  /// such as the transparent Google button overlay on web.
  final bool highlighted;
  final bool busy;

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.busy;
    final down = !widget.busy && (_pressed || widget.highlighted);

    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        transform: Matrix4.translationValues(down ? 2 : 0, down ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: down ? NeoColors.surfaceCream : NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeoColors.inkSolid, width: 2.2),
          boxShadow: down ? NeoShadows.elevation1 : NeoShadows.elevation3,
        ),
        child: Opacity(
          opacity: widget.busy ? 0.6 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      NeoColors.inkSolid,
                    ),
                  ),
                )
              else
                widget.icon,
              const Gap(10),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
