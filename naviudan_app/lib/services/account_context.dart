import '../constants/app_config.dart';
import 'demo_session.dart';
import 'firebase_available.dart';

/// Active account uid (demo session or Firebase).
String? get loggedInUid {
  if (AppConfig.useDemoAuth && DemoSession.instance.isLoggedIn) {
    return DemoSession.instance.uid;
  }
  return currentFirebaseUser?.uid;
}

/// Active account phone (demo session or Firebase).
String? get loggedInPhone {
  if (AppConfig.useDemoAuth && DemoSession.instance.isLoggedIn) {
    return DemoSession.instance.phone;
  }
  return currentFirebaseUser?.phoneNumber;
}
