import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color borderBright;
  final Color accent;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.borderBright,
    required this.accent,
  });

  bool get accentIsLight => accent.computeLuminance() > 0.18;
  Color get accentText => accentIsLight ? const Color(0xFF080808) : const Color(0xFFFFFFFF);
  Color get accentDim => accent.withOpacity(0.18);
}

class C {
  static ThemePreset _preset = presets['terminal']!;

  static void applyPreset(String presetId) {
    _preset = presets[presetId] ?? presets['terminal']!;
  }

  static Color get bg => _preset.bg;
  static Color get surface => _preset.surface;
  static Color get card => _preset.card;
  static Color get border => _preset.border;
  static Color get borderBright => _preset.borderBright;
  static Color get accent => _preset.accent;
  static Color get accentDim => _preset.accentDim;
  static Color get accentText => _preset.accentText;
  static Color get userBorder => _preset.accent;
  static Color get userBg => _preset.card;

  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF666666);
  static const grey3 = Color(0xFF333333);
  static const code = Color(0xFF00FF9C);
  static const codeDim = Color(0x2200FF9C);
  static const error = Color(0xFFFF4444);
  static const errorDim = Color(0x22FF4444);
  static const success = Color(0xFF00FF9C);

  static const presets = <String, ThemePreset>{
    'terminal': ThemePreset(
      id: 'terminal',
      name: 'TERMINAL',
      bg: Color(0xFF080808),
      surface: Color(0xFF111111),
      card: Color(0xFF161616),
      border: Color(0xFF222222),
      borderBright: Color(0xFF333333),
      accent: Color(0xFFE8FF47),
    ),
    'abyss': ThemePreset(
      id: 'abyss',
      name: 'ABYSS',
      bg: Color(0xFF060810),
      surface: Color(0xFF0D1117),
      card: Color(0xFF131A21),
      border: Color(0xFF1A2535),
      borderBright: Color(0xFF253545),
      accent: Color(0xFF00E5CC),
    ),
    'matrix': ThemePreset(
      id: 'matrix',
      name: 'MATRIX',
      bg: Color(0xFF060C06),
      surface: Color(0xFF0D140D),
      card: Color(0xFF121A12),
      border: Color(0xFF1A2A1A),
      borderBright: Color(0xFF243A24),
      accent: Color(0xFF39FF14),
    ),
    'oxide': ThemePreset(
      id: 'oxide',
      name: 'OXIDE',
      bg: Color(0xFF0D0806),
      surface: Color(0xFF14100A),
      card: Color(0xFF1A150E),
      border: Color(0xFF2A1E10),
      borderBright: Color(0xFF3A2A16),
      accent: Color(0xFFFF6B35),
    ),
    'cobalt': ThemePreset(
      id: 'cobalt',
      name: 'COBALT',
      bg: Color(0xFF06080E),
      surface: Color(0xFF0D1018),
      card: Color(0xFF12161F),
      border: Color(0xFF1A2030),
      borderBright: Color(0xFF242C40),
      accent: Color(0xFF5B8AF5),
    ),
  };
}
