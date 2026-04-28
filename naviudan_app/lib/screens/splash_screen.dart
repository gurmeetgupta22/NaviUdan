import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'auth/login_screen.dart';
import 'job_finder/home_screen.dart';
import 'recruiter/recruiter_home_screen.dart';
import '../services/account_context.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final uid = loggedInUid;
    if (uid == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    try {
      final profile = await ApiService.getProfile(uid)
          .timeout(const Duration(seconds: 12));
      final role = profile['role'] as String? ?? 'job_finder';
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'recruiter'
              ? const RecruiterHomeScreen()
              : const JobFinderHomeScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _tricolorTitle() {
    const base = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      height: 1.1,
    );
    // Saffron · Ashoka navy (centre on white) · India green
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Navi', style: base.copyWith(color: AppColors.saffron)),
          Text('U', style: base.copyWith(color: AppColors.navyAshoka)),
          Text('dan', style: base.copyWith(color: AppColors.secondaryGreen)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TricolorTriangleBadge(),
                const SizedBox(height: 16),
                _tricolorTitle(),
                const SizedBox(height: 20),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    AppStrings.sdgLabel,
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.saffron,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small upright tricolour triangle (saffron · white band · green) with navy outline.
class _TricolorTriangleBadge extends StatelessWidget {
  const _TricolorTriangleBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 48,
      child: CustomPaint(painter: _TricolorTrianglePainter()),
    );
  }
}

class _TricolorTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final apex = Offset(w / 2, 0);
    final br = Offset(w, h);
    final bl = Offset(0, h);
    final path = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.navyAshoka,
    );

    canvas.save();
    canvas.clipPath(path);
    final stripe = h / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, stripe), Paint()..color = AppColors.saffron);
    canvas.drawRect(
      Rect.fromLTWH(0, stripe, w, stripe),
      Paint()..color = AppColors.tricolorWhite,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, stripe * 2, w, stripe + 1),
      Paint()..color = AppColors.indiaGreen,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
