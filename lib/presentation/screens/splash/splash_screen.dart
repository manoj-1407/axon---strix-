import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axon/core/theme/app_colors.dart';
import 'package:axon/presentation/screens/conversation/conversation_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final String _title = 'AXON';
  final String _sub = 'precision intelligence';
  int _visibleChars = 0;
  bool _showSub = false;
  bool _showScan = false;
  bool _showCursor = true;
  Timer? _charTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });

    _charTimer = Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (!mounted) return;
      setState(() => _visibleChars++);
      if (_visibleChars >= _title.length) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showScan = true);
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showSub = true);
        });
        Future.delayed(const Duration(milliseconds: 1600), () {
          _cursorTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ConversationListScreen(),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _charTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title.substring(0, _visibleChars.clamp(0, _title.length)),
                  style: GoogleFonts.spaceGrotesk(
                    color: C.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showCursor && _visibleChars < _title.length ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 80),
                  child: Text(
                    '_',
                    style: GoogleFonts.jetBrainsMono(
                      color: C.accent,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedOpacity(
              opacity: _showScan ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 220,
                height: 1,
                color: C.accent,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              opacity: _showSub ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _sub,
                style: GoogleFonts.jetBrainsMono(
                  color: C.grey2,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
