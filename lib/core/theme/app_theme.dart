import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axon/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get current {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: ColorScheme.dark(
        primary: C.accent,
        secondary: C.code,
        surface: C.card,
        error: C.error,
        onPrimary: C.accentText,
        onSecondary: C.bg,
        onSurface: C.white,
        outline: C.border,
      ),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: C.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: C.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: C.grey1, size: 20),
      ),
      cardTheme: CardTheme(
        color: C.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: C.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: C.accent, width: 1),
        ),
        hintStyle: GoogleFonts.spaceGrotesk(color: C.grey2, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.accent,
          foregroundColor: C.accentText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      dividerTheme: DividerThemeData(color: C.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: C.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.zero)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: C.card,
        contentTextStyle: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: C.border)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: C.grey1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? C.accentText : C.grey2),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? C.accent : C.border),
      ),
    );
  }

  static TextTheme _textTheme() => TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 48, fontWeight: FontWeight.w800),
    displayMedium: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 24, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 16, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 12, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 15, height: 1.65),
    bodyMedium: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 14, height: 1.6),
    bodySmall: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 12, height: 1.5),
    labelLarge: GoogleFonts.spaceGrotesk(color: C.white, fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: GoogleFonts.spaceGrotesk(color: C.grey1, fontSize: 11),
  );
}
