import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:web/web.dart' as web;

import 'auth_social_button.dart';
import 'google_sign_in_button_types.dart';
import 'social_icons.dart';

Widget buildWebGoogleSignInButton({
  required GoogleIdTokenCallback onIdToken,
  required GoogleSignInErrorCallback onError,
  required String label,
  required bool signUp,
}) {
  return _GoogleSignInWebButton(
    onIdToken: onIdToken,
    onError: onError,
    label: label,
    signUp: signUp,
  );
}

class _GoogleSignInWebButton extends StatefulWidget {
  const _GoogleSignInWebButton({
    required this.onIdToken,
    required this.onError,
    required this.label,
    required this.signUp,
  });

  final GoogleIdTokenCallback onIdToken;
  final GoogleSignInErrorCallback onError;
  final String label;
  final bool signUp;

  @override
  State<_GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

/// Draws the Neo button in Flutter and lays Google's rendered button over it
/// at zero opacity. GIS only issues ID tokens from its own iframe button, so
/// the iframe must stay on top to receive the click.
class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  static Future<void>? _initialization;
  static const double _maxGisWidth = 400;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  Widget? _host;
  web.HTMLElement? _hostElement;
  double? _gisWidth;
  bool _hovered = false;
  bool _busy = false;

  Future<void> _initialize() {
    final clientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: clientId.isEmpty ? null : clientId,
    );
  }

  @override
  void initState() {
    super.initState();
    _events = GoogleSignIn.instance.authenticationEvents.listen(
      _onAuthEvent,
      onError: (_) => widget.onError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ'),
    );
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn || _busy) return;
    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      widget.onError('Google ไม่ได้ส่ง ID token กลับมา');
      return;
    }
    _setBusy(true);
    try {
      await widget.onIdToken(idToken);
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _hostElement?.style.pointerEvents = value ? 'none' : 'auto';
    if (mounted) {
      setState(() {
        _busy = value;
        if (value) _hovered = false;
      });
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (mounted && _hovered != value) setState(() => _hovered = value);
  }

  Future<void> _renderHost(Object element) async {
    final host = element as web.HTMLElement;
    _hostElement = host;
    host.style
      ..width = '100%'
      ..height = '100%'
      ..overflow = 'hidden'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..opacity = '0';
    host.addEventListener(
      'mouseenter',
      ((web.Event _) => _setHovered(true)).toJS,
    );
    host.addEventListener(
      'mouseleave',
      ((web.Event _) => _setHovered(false)).toJS,
    );

    try {
      await _initialize();
    } catch (_) {
      if (mounted) {
        widget.onError('ตั้งค่า Google Sign-In ไม่ครบ ตรวจสอบ OAuth Client ID');
      }
      return;
    }
    if (!mounted) return;
    gis.id.renderButton(
      host,
      gis.GsiButtonConfiguration(
        type: gis.ButtonType.standard,
        theme: gis.ButtonTheme.outline,
        size: gis.ButtonSize.large,
        text: widget.signUp
            ? gis.ButtonText.signup_with
            : gis.ButtonText.signin_with,
        shape: gis.ButtonShape.rectangular,
        logo_alignment: gis.ButtonLogoAlignment.center,
        width: _gisWidth,
        locale: 'th',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        _gisWidth ??= (maxWidth.isFinite ? maxWidth : 320.0)
            .clamp(80.0, _maxGisWidth)
            .roundToDouble();
        return SizedBox(
          height: 50,
          child: Stack(
            children: [
              Positioned.fill(
                child: AuthSocialButton(
                  label: _busy ? 'กำลังเชื่อมต่อ…' : widget.label,
                  icon: const GoogleGIcon(),
                  onTap: null,
                  highlighted: _hovered,
                  busy: _busy,
                ),
              ),
              Positioned.fill(
                child: _host ??= HtmlElementView.fromTagName(
                  tagName: 'div',
                  onElementCreated: _renderHost,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
