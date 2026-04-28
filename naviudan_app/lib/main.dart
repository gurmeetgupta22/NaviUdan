import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/app_config.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'services/demo_session.dart';
import 'providers/user_provider.dart';
import 'providers/job_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoSession.instance.init();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  if (!AppConfig.useDemoAuth) {
    try {
      if (kIsWeb) {
        if (DefaultFirebaseOptions.isWebConfigured) {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
        }
      } else {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  runApp(const NaviUdanApp());
}

class NaviUdanApp extends StatelessWidget {
  const NaviUdanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
      ],
      child: MaterialApp(
        title: 'NaviUdan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
