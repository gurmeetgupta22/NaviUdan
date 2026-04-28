// Paste your Web app config from Firebase Console:
// Project settings (gear) → Your apps → Web (`</>`) → copy firebaseConfig values.
// If there is no web app, click "Add app" → Web and register (localhost is allowed for dev).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    authDomain: '',
    storageBucket: '',
  );

  /// True when the Web app block from Firebase Console is fully pasted.
  static bool get isWebConfigured =>
      web.apiKey.isNotEmpty &&
      web.appId.isNotEmpty &&
      web.projectId.isNotEmpty &&
      web.messagingSenderId.isNotEmpty &&
      (web.authDomain?.isNotEmpty ?? false) &&
      (web.storageBucket?.isNotEmpty ?? false);
}
