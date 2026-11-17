import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Colours used across the app, one set per brightness.
class Palette {
  const Palette({
    required this.bg,
    required this.card,
    required this.cardHigh,
    required this.line,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.danger,
    required this.blue,
  });

  final Color bg;
  final Color card;
  final Color cardHigh;
  final Color line;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color gold;
  final Color danger;
  final Color blue;

  static const dark = Palette(
    bg: Color(0xFF0C0D10),
    card: Color(0xFF16181D),
    cardHigh: Color(0xFF20232A),
    line: Color(0xFF2A2E37),
    text: Color(0xFFF3F4F6),
    muted: Color(0xFF8E94A1),
    accent: Color(0xFFC5F82A),
    onAccent: Color(0xFF0C0D10),
    gold: Color(0xFFFFC53D),
    danger: Color(0xFFFF6B6B),
    blue: Color(0xFF6AA8FF),
  );

  static const light = Palette(
    bg: Color(0xFFF3F4F7),
    card: Color(0xFFFFFFFF),
    cardHigh: Color(0xFFECEEF2),
    line: Color(0xFFDFE2E8),
    text: Color(0xFF111317),
    muted: Color(0xFF687080),
    accent: Color(0xFF3D7A00),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFB7791F),
    danger: Color(0xFFD23B3B),
    blue: Color(0xFF2F6FDB),
  );
}

extension PaletteX on BuildContext {
  Palette get p => Theme.of(this).brightness == Brightness.dark
      ? Palette.dark
      : Palette.light;
}

/// Digits that keep the same width, so timers and tables do not jitter.
const tabular = [FontFeature.tabularFigures()];

/// One colour per muscle group, used for avatars and distribution bars.
Color muscleColor(String muscle) => switch (muscle) {
  'Chest' => const Color(0xFFFF7A59),
  'Back' => const Color(0xFF5B9DFF),
  'Shoulders' => const Color(0xFFFFC53D),
  'Biceps' => const Color(0xFFB085FF),
  'Triceps' => const Color(0xFFFF8AC2),
  'Forearms' => const Color(0xFFC9A27E),
  'Core' => const Color(0xFF4DD4C6),
  'Quads' => const Color(0xFF7BDC6B),
  'Hamstrings' => const Color(0xFF3FBF8F),
  'Glutes' => const Color(0xFFF28B50),
  'Calves' => const Color(0xFF8FB3FF),
  'Cardio' => const Color(0xFFFF6B6B),
  _ => const Color(0xFF9AA3B2),
};

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final p = dark ? Palette.dark : Palette.light;
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        secondary: p.accent,
        onSecondary: p.onAccent,
        tertiary: p.gold,
        surface: p.bg,
        onSurface: p.text,
        onSurfaceVariant: p.muted,
        surfaceContainerLowest: p.bg,
        surfaceContainerLow: p.card,
        surfaceContainer: p.card,
        surfaceContainerHigh: p.cardHigh,
        surfaceContainerHighest: p.cardHigh,
        outline: p.line,
        outlineVariant: p.line,
        error: p.danger,
        onError: Colors.white,
        primaryContainer: p.accent.withValues(alpha: 0.16),
        onPrimaryContainer: p.accent,
        secondaryContainer: p.accent.withValues(alpha: 0.16),
        onSecondaryContainer: p.accent,
        surfaceTint: Colors.transparent,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: p.bg,
    splashFactory: InkSparkle.splashFactory,
  );

  final text = base.textTheme
      .apply(bodyColor: p.text, displayColor: p.text)
      .copyWith(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: p.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: p.text,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
          color: p.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: p.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: p.text,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: p.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
        labelMedium: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: p.muted,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: p.muted,
        ),
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  const buttonText = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: buttonShape,
        side: BorderSide(color: p.line),
        foregroundColor: p.text,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: buttonText.copyWith(fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: 2,
      extendedTextStyle: buttonText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.cardHigh,
      hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
      labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
      floatingLabelStyle: TextStyle(
        color: p.accent,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      elevation: 0,
      height: 68,
      indicatorColor: p.accent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: s.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      modalBackgroundColor: p.card,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.cardHigh,
      contentTextStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.card,
      selectedColor: p.accent,
      side: BorderSide(color: p.line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: p.onAccent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.cardHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: text.bodyMedium,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.muted,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      subtitleTextStyle: text.bodySmall,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccent : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.cardHigh,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.line),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.cardHigh,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(buttonText.copyWith(fontSize: 13)),
        side: WidgetStatePropertyAll(BorderSide(color: p.line)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAccent : p.text,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.card,
        ),
      ),
    ),
  );
}
