import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class BuaColors {
  static const brandBlue = Color(0xFF1554C0);
  static const brandYellow = Color(0xFFFFD447);
  static const ink = Color(0xFF12372A);
  static const inkSoft = Color(0xFF1C4A36);
  static const leaf = Color(0xFF2F6B4F);
  static const lime = Color(0xFFD9F27A);
  static const limeSoft = Color(0xFFEDF7C4);
  static const cream = Color(0xFFF4EEE0);
  static const paper = Color(0xFFFFFDF7);
  static const line = Color(0xFFE4DBC8);
  static const lineSoft = Color(0xFFF0E8D8);
  static const tomato = Color(0xFFC2410C);
  static const tomatoSoft = Color(0xFFFBE3D6);
  static const honey = Color(0xFFB45309);
  static const honeySoft = Color(0xFFF8E7C4);
  static const water = Color(0xFF3F7C85);
  static const waterSoft = Color(0xFFE2EFF0);
  static const muted = Color(0xFF55655A);
  static const muted2 = Color(0xFF66766B);
  static const over = Color(0xFFFFA07A);
}

TextStyle serifStyle(
  double size, {
  Color color = BuaColors.ink,
  double height = 1.04,
  double letterSpacing = -0.6,
  double weight = 540,
}) => TextStyle(
  fontFamily: 'Fraunces',
  fontSize: size,
  height: height,
  letterSpacing: letterSpacing,
  color: color,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', weight)],
);

TextStyle numberStyle(
  double size, {
  Color color = BuaColors.ink,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontFamily: 'BeVietnamPro',
  fontSize: size,
  color: color,
  fontWeight: weight,
  fontFeatures: const [FontFeature.tabularFigures()],
  letterSpacing: -0.2,
);

ThemeData buildBuaTheme() {
  final scheme = const ColorScheme.light(
    primary: BuaColors.ink,
    onPrimary: BuaColors.paper,
    secondary: BuaColors.lime,
    onSecondary: BuaColors.ink,
    tertiary: BuaColors.tomato,
    onTertiary: Colors.white,
    surface: BuaColors.paper,
    onSurface: BuaColors.ink,
    error: BuaColors.tomato,
    onError: Colors.white,
    outline: BuaColors.line,
    surfaceContainerHighest: BuaColors.cream,
  );

  final textTheme = TextTheme(
    displayLarge: serifStyle(48, height: 0.98, letterSpacing: -1.4),
    displayMedium: serifStyle(38, letterSpacing: -1.1),
    displaySmall: serifStyle(30, letterSpacing: -0.8),
    headlineMedium: serifStyle(26, letterSpacing: -0.7),
    headlineSmall: serifStyle(22, letterSpacing: -0.5),
    titleLarge: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: BuaColors.ink,
      letterSpacing: -0.2,
    ),
    titleMedium: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: BuaColors.ink,
      letterSpacing: -0.1,
    ),
    titleSmall: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: BuaColors.ink,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 15,
      height: 1.5,
      color: BuaColors.ink,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 13.5,
      height: 1.5,
      color: BuaColors.ink,
    ),
    bodySmall: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 11.5,
      height: 1.5,
      color: BuaColors.muted,
    ),
    labelLarge: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: BuaColors.ink,
    ),
    labelMedium: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: BuaColors.muted,
    ),
    labelSmall: const TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: BuaColors.muted2,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: BuaColors.cream,
    fontFamily: 'BeVietnamPro',
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: BuaColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: serifStyle(24, letterSpacing: -0.5),
      iconTheme: const IconThemeData(color: BuaColors.ink),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BuaColors.paper,
      hintStyle: const TextStyle(
        fontFamily: 'BeVietnamPro',
        color: BuaColors.muted2,
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'BeVietnamPro',
        color: BuaColors.muted,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: BuaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: BuaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: BuaColors.leaf, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: BuaColors.tomato),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: BuaColors.tomato, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BuaColors.lime,
        foregroundColor: BuaColors.ink,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BuaColors.ink,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: BuaColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BuaColors.leaf,
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: BuaColors.ink,
        minimumSize: const Size(44, 44),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: BuaColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 13,
        color: BuaColors.paper,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      actionTextColor: BuaColors.lime,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BuaColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: serifStyle(23, letterSpacing: -0.4),
      contentTextStyle: const TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 14,
        height: 1.55,
        color: BuaColors.muted,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BuaColors.paper,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: BuaColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: BuaColors.line,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BuaColors.leaf,
      linearTrackColor: BuaColors.lineSoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BuaColors.ink
            : BuaColors.paper,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BuaColors.lime
            : BuaColors.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(BuaColors.line),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: BuaColors.leaf,
      selectionColor: BuaColors.limeSoft,
      selectionHandleColor: BuaColors.leaf,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
