import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import 'demo_session.dart';

class AuthService {
  String? _verificationId;
  int? _resendToken;

  FirebaseAuth? get _auth =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance;

  User? get currentUser => AppConfig.useDemoAuth ? null : _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream<User?>.value(null);

  /// Send OTP to the given phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String error) onError,
  }) async {
    if (AppConfig.useDemoAuth) {
      await DemoSession.instance.setPendingPhone(phoneNumber);
      onCodeSent();
      return;
    }

    final auth = _auth;
    if (auth == null) {
      onError(
        'Firebase is not set up for web. Open lib/firebase_options.dart and paste '
        'your Web app values from Firebase Console → Project settings → Your apps (</>).',
      );
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify OTP and sign in
  Future<UserCredential?> verifyOtp(String otp) async {
    if (AppConfig.useDemoAuth) {
      if (otp != AppConfig.demoOtp) {
        throw Exception('Invalid OTP');
      }
      final pending = DemoSession.instance.pendingPhone;
      if (pending == null || pending.isEmpty) {
        throw Exception('Session expired. Go back and send OTP again.');
      }
      final digits = pending.replaceAll(RegExp(r'\D'), '');
      final uid = 'demo_$digits';
      await DemoSession.instance.signIn(uid: uid, phone: pending);
      return null;
    }

    if (_verificationId == null) {
      throw Exception('Verification ID is null. Please resend OTP.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not configured.');
    }
    return await auth.signInWithCredential(credential);
  }

  /// Get current user's Firebase ID token
  Future<String?> getIdToken() async {
    if (AppConfig.useDemoAuth) return null;
    return await _auth?.currentUser?.getIdToken();
  }

  /// Sign out
  Future<void> signOut() async {
    if (AppConfig.useDemoAuth) {
      await DemoSession.instance.signOut();
      return;
    }
    final auth = _auth;
    if (auth != null) await auth.signOut();
  }

  bool get isLoggedIn =>
      AppConfig.useDemoAuth ? DemoSession.instance.isLoggedIn : (_auth?.currentUser != null);

  String? get currentUid =>
      AppConfig.useDemoAuth ? DemoSession.instance.uid : _auth?.currentUser?.uid;

  String? get currentPhone =>
      AppConfig.useDemoAuth ? DemoSession.instance.phone : _auth?.currentUser?.phoneNumber;
}
