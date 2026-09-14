import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_split/shared/theme/app_theme.dart';

void main() {
  test('Material 3 디자인 계약을 전역 테마에 고정한다', () {
    final theme = AppTheme.light;
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final cardRadius = cardShape.borderRadius as BorderRadius;
    final appBarBorder = theme.appBarTheme.shape! as Border;
    final inputShape = theme.inputDecorationTheme.border! as OutlineInputBorder;
    final buttonSize = theme.filledButtonTheme.style!.minimumSize!.resolve(
      <WidgetState>{},
    );
    final buttonShape =
        theme.filledButtonTheme.style!.shape!.resolve(<WidgetState>{})!
            as RoundedRectangleBorder;
    final buttonRadius = buttonShape.borderRadius as BorderRadius;
    final outlinedSide = theme.outlinedButtonTheme.style!.side!.resolve(
      <WidgetState>{},
    );
    final selectedLabel = theme.navigationBarTheme.labelTextStyle!.resolve({
      WidgetState.selected,
    });
    final selectedIcon = theme.navigationBarTheme.iconTheme!.resolve({
      WidgetState.selected,
    });

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTheme.primary);
    expect(theme.colorScheme.onPrimary, Colors.white);
    expect(theme.colorScheme.primaryContainer, AppTheme.primaryContainer);
    expect(theme.colorScheme.onSurface, AppTheme.ink);
    expect(theme.colorScheme.onSurfaceVariant, AppTheme.mutedInk);
    expect(theme.scaffoldBackgroundColor, AppTheme.canvas);
    expect(cardRadius.topLeft, Radius.zero);
    expect(cardShape.side.color, AppTheme.ink);
    expect(cardShape.side.width, AppTheme.frameStroke);
    expect(theme.dividerTheme.color, AppTheme.line);
    expect(theme.dividerTheme.thickness, AppTheme.rowStroke);
    expect(appBarBorder.bottom.color, AppTheme.ink);
    expect(appBarBorder.bottom.width, AppTheme.sectionStroke);
    expect(
      inputShape.borderRadius.topLeft,
      const Radius.circular(AppTheme.controlCornerRadius),
    );
    expect(
      buttonRadius.topLeft,
      const Radius.circular(AppTheme.buttonCornerRadius),
    );
    expect(outlinedSide?.width, AppTheme.outlineStroke);
    expect(buttonSize?.height, AppTheme.minimumTouchTarget);
    expect(theme.textTheme.displayLarge?.fontSize, 48);
    expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
    expect(theme.textTheme.headlineSmall?.fontSize, 24);
    expect(theme.textTheme.headlineSmall?.fontWeight, FontWeight.w700);
    expect(theme.textTheme.labelLarge?.fontFamily, 'monospace');
    expect(theme.appBarTheme.toolbarHeight, AppTheme.appBarHeight);
    expect(theme.navigationBarTheme.height, AppTheme.navigationHeight);
    expect(AppTheme.gridUnit, 8);
    expect(AppTheme.denseUnit, 4);
    expect(AppTheme.mediumBreakpoint, 720);
    expect(AppTheme.expandedBreakpoint, 1100);
    expect(theme.navigationBarTheme.indicatorColor, AppTheme.primaryPressed);
    expect(selectedIcon?.color, Colors.white);
    expect(selectedLabel?.fontWeight, FontWeight.w700);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
  });
}
