import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axon/core/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  bool _show = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _show = !_show);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Row(
        children: [
          Text(
            'axon is thinking',
            style: GoogleFonts.jetBrainsMono(
              color: C.grey2,
              fontSize: 13,
            ),
          ),
          AnimatedOpacity(
            opacity: _show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 80),
            child: Text(
              '_',
              style: GoogleFonts.jetBrainsMono(color: C.accent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
