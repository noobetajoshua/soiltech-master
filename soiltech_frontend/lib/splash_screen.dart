import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'menu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 3);

  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  static const Color backgroundColor = Color.fromARGB(255, 248, 249, 247);
  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color mutedText = Color(0xFF7A7F48);
  static const Color progressTrack = Color(0xFFF0E7C4);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    _progressAnimation = Tween<double>(
      begin: 0.05,
      end: 0.72,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => session != null
            ? const MenuScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.36;
    final progressWidth = screenWidth * 0.68;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    color: const Color(0xFFF8F3D9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    'assets/logo/soiltech_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 34),

                const Text(
                  'SoilTech',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Soil scanning and crop recommendatios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: mutedText,
                  ),
                ),

                const SizedBox(height: 48),

                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(progressWidth, 42),
                      painter: SoilTechProgressPainter(
                        progress: _progressAnimation.value,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Scanning soil data...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: mutedText,
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

class SoilTechProgressPainter extends CustomPainter {
  final double progress;

  SoilTechProgressPainter({
    required this.progress,
  });

  static const Color fillStart = Color(0xFF80B155);
  static const Color fillEnd = Color(0xFFC1D95C);
  static const Color trackColor = Color(0xFFF0E7C4);
  static const Color sproutColor = Color(0xFF498428);

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = 18;
    final double barTop = size.height / 2 - barHeight / 2;
    final double radius = barHeight / 2;

    final Rect trackRect = Rect.fromLTWH(
      0,
      barTop,
      size.width,
      barHeight,
    );

    final RRect trackRRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(radius),
    );

    final Paint trackPaint = Paint()
      ..color = trackColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(trackRRect, trackPaint);

    final double filledWidth = size.width * progress;

    final Rect fillRect = Rect.fromLTWH(
      0,
      barTop,
      filledWidth,
      barHeight,
    );

    final RRect fillRRect = RRect.fromRectAndRadius(
      fillRect,
      Radius.circular(radius),
    );

    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          fillStart,
          fillEnd,
        ],
      ).createShader(fillRect);

    canvas.drawRRect(fillRRect, fillPaint);

    _drawTinySprout(
      canvas,
      Offset(filledWidth, barTop - 1),
    );
  }

  void _drawTinySprout(Canvas canvas, Offset base) {
    final Paint stemPaint = Paint()
      ..color = sproutColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint leafPaint = Paint()
      ..color = sproutColor
      ..style = PaintingStyle.fill;

    final double x = base.dx;
    final double y = base.dy;

    final Path stem = Path()
      ..moveTo(x, y + 9)
      ..quadraticBezierTo(x, y - 2, x, y - 13);

    canvas.drawPath(stem, stemPaint);

    final Path leftLeaf = Path()
      ..moveTo(x, y - 7)
      ..cubicTo(
        x - 15,
        y - 18,
        x - 17,
        y - 1,
        x,
        y - 3,
      )
      ..close();

    final Path rightLeaf = Path()
      ..moveTo(x, y - 9)
      ..cubicTo(
        x + 15,
        y - 20,
        x + 18,
        y - 2,
        x,
        y - 4,
      )
      ..close();

    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant SoilTechProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}