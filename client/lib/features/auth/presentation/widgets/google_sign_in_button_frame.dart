import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Resizes the viewport without remounting the Google iframe during a drag.
class GoogleSignInButtonFrame extends StatefulWidget {
  const GoogleSignInButtonFrame({super.key, required this.builder});

  final Widget Function(double width) builder;

  @override
  State<GoogleSignInButtonFrame> createState() =>
      _GoogleSignInButtonFrameState();
}

class _GoogleSignInButtonFrameState extends State<GoogleSignInButtonFrame> {
  double? _renderWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final outerWidth = constraints.maxWidth.isFinite
          ? math.min(constraints.maxWidth, 400.0)
          : 320.0;
      // Leave room for the GIS iframe's surrounding gutter, not just our border.
      final buttonWidth = math.max(0.0, outerWidth - 24).floorToDouble();
      _renderWidth ??= buttonWidth;
      return Container(
        width: outerWidth,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeoColors.inkSolid, width: 2.2),
          boxShadow: NeoShadows.elevation3,
        ),
        child: SizedBox(
          width: buttonWidth,
          height: 44,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: _renderWidth,
              height: 44,
              child: widget.builder(_renderWidth!),
            ),
          ),
        ),
      );
    },
  );
}
