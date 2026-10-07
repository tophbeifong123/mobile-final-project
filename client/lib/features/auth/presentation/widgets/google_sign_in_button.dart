import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_social_button.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart'
    as google_web;
import 'google_sign_in_button_types.dart';
import 'social_icons.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onIdToken,
    required this.onError,
    this.label = 'เข้าสู่ระบบด้วย Google',
    this.signUp = false,
  });

  final GoogleIdTokenCallback onIdToken;
  final ValueChanged<String> onError;
  final String label;
  final bool signUp;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  static Future<void>? _initialization;
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  bool _busy = false;

  GoogleSignIn get _google => GoogleSignIn.instance;

  Future<void> _initialize() {
    return _initialization ??= _google.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
  }

  Future<void> _signInAndroid() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _initialize();
      if (!_google.supportsAuthenticate()) {
        widget.onError('แพลตฟอร์มนี้ไม่รองรับ Google Sign-In แบบนี้');
        return;
      }
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError('Google ไม่ได้ส่ง ID token กลับมา');
        return;
      }
      await widget.onIdToken(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        widget.onError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
      }
    } catch (_) {
      widget.onError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return google_web.buildWebGoogleSignInButton(
        onIdToken: widget.onIdToken,
        onError: widget.onError,
        label: widget.label,
        signUp: widget.signUp,
      );
    }

    return AuthSocialButton(
      label: _busy ? 'กำลังเชื่อมต่อ…' : widget.label,
      icon: const GoogleGIcon(),
      busy: _busy,
      onTap: _signInAndroid,
    );
  }
}
