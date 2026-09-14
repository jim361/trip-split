import 'package:flutter/material.dart';

/// Trip Split의 Structural Modernism 기반 Material 3 시각 규칙입니다.
abstract final class AppTheme {
  static const primary = Color(0xff1d4ed8);
  static const primaryPressed = Color(0xff0037b0);
  static const primaryContainer = Color(0xffe8efff);
  static const ink = Color(0xff171717);
  static const mutedInk = Color(0xff676762);
  static const line = Color(0xffd4d4ce);
  static const canvas = Color(0xfff2f2ee);
  static const success = Color(0xff18794e);
  static const warning = Color(0xffa15c00);

  static const gridUnit = 8.0;
  static const denseUnit = 4.0;
  static const mediumBreakpoint = 720.0;
  static const expandedBreakpoint = 1100.0;
  static const appBarHeight = 64.0;
  static const navigationHeight = 64.0;
  static const minimumTouchTarget = 48.0;

  static const rowStroke = 1.0;
  static const frameStroke = 1.0;
  static const outlineStroke = 2.0;
  static const sectionStroke = 3.0;
  static const buttonCornerRadius = 2.0;
  static const controlCornerRadius = 4.0;

  static const _buttonRadius = BorderRadius.all(
    Radius.circular(buttonCornerRadius),
  );
  static const _controlRadius = BorderRadius.all(
    Radius.circular(controlCornerRadius),
  );
  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: _buttonRadius,
  );

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryContainer,
          onPrimaryContainer: ink,
          secondary: ink,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xffe8e8e3),
          onSecondaryContainer: ink,
          tertiary: const Color(0xff6f6a52),
          onTertiary: Colors.white,
          error: const Color(0xffb42318),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: ink,
          onSurfaceVariant: mutedInk,
          outline: mutedInk,
          outlineVariant: line,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: canvas,
          surfaceContainer: const Color(0xffeaeae5),
          surfaceContainerHigh: const Color(0xffe3e3de),
          surfaceContainerHighest: const Color(0xffdbdbd5),
        );
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final textTheme = base.textTheme
        .apply(fontFamily: 'sans-serif', bodyColor: ink, displayColor: ink)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 48,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1.92,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.48,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontFamily: 'monospace',
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: 0.6,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            color: ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0.4,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            color: mutedInk,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0.4,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontFamily: 'sans-serif',
            color: mutedInk,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: _controlRadius,
      borderSide: const BorderSide(color: line),
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: line,
        space: rowStroke,
        thickness: rowStroke,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: appBarHeight,
        titleTextStyle: textTheme.labelLarge,
        shape: const Border(
          bottom: BorderSide(color: ink, width: sectionStroke),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: denseUnit),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: ink, width: frameStroke),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: gridUnit * 2,
          vertical: 15,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: const OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: primary, width: outlineStroke),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          minimumSize: const Size.square(minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: _buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.square(minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: ink, width: outlineStroke),
          shape: _buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.square(minimumTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: _buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(minimumTouchTarget),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: primaryContainer,
        side: const BorderSide(color: line),
        shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: navigationHeight,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryPressed,
        indicatorShape: _buttonShape,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : mutedInk,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? primaryPressed
                : mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryPressed,
        indicatorShape: _buttonShape,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: mutedInk),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: primaryPressed,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: mutedInk,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: _controlRadius),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white),
        insetPadding: EdgeInsets.all(gridUnit * 2),
        shape: RoundedRectangleBorder(borderRadius: _buttonRadius),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
