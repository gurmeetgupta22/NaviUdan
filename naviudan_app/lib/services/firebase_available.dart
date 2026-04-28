import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// False when Firebase was never initialized (e.g. web without [DefaultFirebaseOptions]).
bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

User? get currentFirebaseUser =>
    isFirebaseAvailable ? FirebaseAuth.instance.currentUser : null;
