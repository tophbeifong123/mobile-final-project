import 'dart:async';
import 'package:flutter/material.dart';

/// Toast types supported by the Neo-Brutalist design system.
enum AppToastType {
  info,
  success,
  error,
  warning,
}

/// A top-floating Neo-Brutalist Toast notification.
///
/// Positioned directly under the Status Bar / Safe Area (top: 16–24px offset),
/// styled with hard black outlines, sharp drop shadows, and vibrant retro tones.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static AppToastWidgetState? _currentState;

  /// Show a toast floating below the top Safe Area / Status Bar.
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(milliseconds: 2800),
    IconData? icon,
    VoidCallback? onTap,
    double? topOffset,
  }) {
    dismiss(immediate: true);

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlay == null) {
      // Fallback if no Overlay is accessible
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final topPadding = MediaQuery.maybeOf(context)?.padding.top ?? 0.0;
    // Position floating right under the top safe area / status bar
    final resolvedTop = topOffset ??
        (topPadding > 0 ? (topPadding + 16.0) : 20.0);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => AppToastOverlayWidget(
        key: const ValueKey('app_toast_overlay'),
        message: message,
        type: type,
        icon: icon,
        top: resolvedTop,
        onTap: () {
          onTap?.call();
          dismiss();
        },
        onDismissed: () {
          _removeEntry(entry);
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Convenience method for showing a success toast.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2800),
    VoidCallback? onTap,
    double? topOffset,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      duration: duration,
      onTap: onTap,
      topOffset: topOffset,
    );
  }

  /// Convenience method for showing an error toast.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
    VoidCallback? onTap,
    double? topOffset,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      duration: duration,
      onTap: onTap,
      topOffset: topOffset,
    );
  }

  /// Convenience method for showing an info/notice toast.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2800),
    VoidCallback? onTap,
    double? topOffset,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      duration: duration,
      onTap: onTap,
      topOffset: topOffset,
    );
  }

  /// Convenience method for showing a warning toast.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3000),
    VoidCallback? onTap,
    double? topOffset,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      duration: duration,
      onTap: onTap,
      topOffset: topOffset,
    );
  }

  /// Dismiss the currently visible toast.
  static void dismiss({bool immediate = false}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (immediate) {
      if (_currentEntry != null) {
        final entry = _currentEntry!;
        _currentEntry = null;
        _currentState = null;
        if (entry.mounted) {
          entry.remove();
        }
      }
    } else {
      _currentState?.animateOut();
    }
  }

  static void _removeEntry(OverlayEntry entry) {
    if (_currentEntry == entry) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _currentEntry = null;
      _currentState = null;
    }
    if (entry.mounted) {
      entry.remove();
    }
  }
}

/// The overlay widget wrapping the toast banner with top positioning, safe area,
/// constraints, and gestures.
class AppToastOverlayWidget extends StatefulWidget {
  const AppToastOverlayWidget({
    super.key,
    required this.message,
    required this.type,
    required this.top,
    this.icon,
    this.onTap,
    required this.onDismissed,
    this.onStateCreated,
  });

  final String message;
  final AppToastType type;
  final double top;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;
  final void Function(AppToastWidgetState)? onStateCreated;

  @override
  State<AppToastOverlayWidget> createState() => AppToastWidgetState();
}

class AppToastWidgetState extends State<AppToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated?.call(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();
  }

  void animateOut() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case AppToastType.success:
        return const Color(0xFFA7F3D0); // Fresh Mint
      case AppToastType.error:
        return const Color(0xFFFDA4AF); // Soft Rose
      case AppToastType.warning:
        return const Color(0xFFFDBA74); // Pastel Coral
      case AppToastType.info:
        return const Color(0xFFFEF08A); // Butter Yellow
    }
  }

  IconData get _iconData {
    if (widget.icon != null) return widget.icon!;
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
      case AppToastType.warning:
        return Icons.warning_amber_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const inkSolid = Color(0xFF18181B);

    return Positioned(
      top: widget.top,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: widget.onTap ?? animateOut,
                onVerticalDragEnd: (details) {
                  // Swipe up to dismiss
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -100) {
                    animateOut();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: inkSolid, width: 2.2),
                      boxShadow: const [
                        BoxShadow(
                          color: inkSolid,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Pill
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: inkSolid, width: 1.8),
                          ),
                          child: Icon(
                            _iconData,
                            size: 18,
                            color: inkSolid,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Message Text
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: inkSolid,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Close "✕" Button
                        GestureDetector(
                          onTap: animateOut,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: inkSolid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// BuildContext extension for concise toast triggering.
extension AppToastContextX on BuildContext {
  void showAppToast(
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(milliseconds: 2800),
    IconData? icon,
    VoidCallback? onTap,
    double? topOffset,
  }) {
    AppToast.show(
      this,
      message: message,
      type: type,
      duration: duration,
      icon: icon,
      onTap: onTap,
      topOffset: topOffset,
    );
  }

  void showSuccessToast(String message, {Duration? duration}) {
    AppToast.success(this, message, duration: duration ?? const Duration(milliseconds: 2800));
  }

  void showErrorToast(String message, {Duration? duration}) {
    AppToast.error(this, message, duration: duration ?? const Duration(milliseconds: 3200));
  }

  void showInfoToast(String message, {Duration? duration}) {
    AppToast.info(this, message, duration: duration ?? const Duration(milliseconds: 2800));
  }

  void showWarningToast(String message, {Duration? duration}) {
    AppToast.warning(this, message, duration: duration ?? const Duration(milliseconds: 3000));
  }
}
