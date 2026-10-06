import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

import '../../../../core/theme/app_tokens.dart';
import 'google_sign_in_button_types.dart';

Widget buildWebGoogleSignInButton({
  required GoogleIdTokenCallback onIdToken,
  required GoogleSignInErrorCallback onError,
}) {
  return _GoogleSignInWebButton(onIdToken: onIdToken, onError: onError);
}

class _GoogleSignInWebButton extends StatefulWidget {
  const _GoogleSignInWebButton({
    required this.onIdToken,
    required this.onError,
  });

  final GoogleIdTokenCallback onIdToken;
  final GoogleSignInErrorCallback onError;

  @override
  State<_GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  static Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;

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
    _initialize().catchError((Object _) {
      widget.onError('ตั้งค่า Google Sign-In ไม่ครบ ตรวจสอบ OAuth Client ID');
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 46,
            child: Center(
              child: Text(
                'ตั้งค่า Web Client ID ก่อน',
                style: TextStyle(fontSize: 11, color: NeoColors.errorText),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 46,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            // GSI renders an HTML button, so it cannot inherit Flutter's
            // Expanded width unless we pass the measured width explicitly.
            final buttonWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(1.0, 400.0).toDouble()
                : 150.0;

            return SizedBox(
              height: 46,
              width: buttonWidth,
              child: google_web.renderButton(
                configuration: google_web.GSIButtonConfiguration(
                  type: google_web.GSIButtonType.standard,
                  theme: google_web.GSIButtonTheme.outline,
                  size: google_web.GSIButtonSize.large,
                  text: google_web.GSIButtonText.continueWith,
                  shape: google_web.GSIButtonShape.rectangular,
                  minimumWidth: buttonWidth,
                  locale: 'th',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
