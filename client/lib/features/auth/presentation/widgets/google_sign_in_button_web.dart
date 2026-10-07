import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:web/web.dart' as web;

import 'google_sign_in_button_frame.dart';
import 'google_sign_in_button_types.dart';

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

class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  static Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  bool _ready = false;
  Widget? _host;

  Future<void> _initialize() {
    final clientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: clientId.isEmpty ? null : clientId,
    );
  }

  @override
  void initState() {
    super.initState();
    _events = GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is! GoogleSignInAuthenticationEventSignIn) return;
      final idToken = event.user.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError('Google ไม่ได้ส่ง ID token กลับมา');
        return;
      }
      await widget.onIdToken(idToken);
    }, onError: (_) => widget.onError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ'));
    _initialize()
        .then((_) {
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (mounted) {
            widget.onError(
              'ตั้งค่า Google Sign-In ไม่ครบ ตรวจสอบ OAuth Client ID',
            );
          }
        });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  void _renderHost(Object element, double width) {
    final host = element as web.HTMLElement;
    host.style
      ..width = '100%'
      ..height = '100%'
      ..overflow = 'visible'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center';
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
        width: width,
        locale: 'th',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GoogleSignInButtonFrame(
        builder: (width) => _ready
            ? _host ??= HtmlElementView.fromTagName(
                tagName: 'div',
                onElementCreated: (element) => _renderHost(element, width),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
