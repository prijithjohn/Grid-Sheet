import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/core/theme/app_colors.dart';
import 'package:grid_sheet/core/theme/app_dimensions.dart';
import 'package:grid_sheet/core/theme/app_theme.dart';
import 'package:grid_sheet/core/theme/app_typography.dart';

void main() {
  group('Phase 03A: Theme Token Tests', () {
    group('AppColors — Grid Professional Light Palette', () {
      test('primary brand green matches #217346', () {
        expect(AppColors.primary.toARGB32(), 0xFF217346);
      });

      test('primaryContainer selection green matches #107C41', () {
        expect(AppColors.primaryContainer.toARGB32(), 0xFF107C41);
      });

      test('deepGreen matches #185C37', () {
        expect(AppColors.deepGreen.toARGB32(), 0xFF185C37);
      });

      test('selectionFill matches #E2F0D9', () {
        expect(AppColors.selectionFill.toARGB32(), 0xFFE2F0D9);
      });

      test('recessedChrome matches #F5F7F6', () {
        expect(AppColors.recessedChrome.toARGB32(), 0xFFF5F7F6);
      });

      test('canvasWhite matches #FFFFFF', () {
        expect(AppColors.canvasWhite.toARGB32(), 0xFFFFFFFF);
      });

      test('gridline color matches #E3E7E4', () {
        expect(AppColors.gridline.toARGB32(), 0xFFE3E7E4);
      });

      test('neutralBorder matches #D9E1DC', () {
        expect(AppColors.neutralBorder.toARGB32(), 0xFFD9E1DC);
      });

      test('textPrimary matches #202124', () {
        expect(AppColors.textPrimary.toARGB32(), 0xFF202124);
      });

      test('textSecondary matches #5F6B63', () {
        expect(AppColors.textSecondary.toARGB32(), 0xFF5F6B63);
      });
    });

    group('AppDimensions — Layout Tokens', () {
      test('titleBarHeight is 36px', () {
        expect(AppDimensions.titleBarHeight, 36.0);
      });

      test('ribbonTabHeight is 32px', () {
        expect(AppDimensions.ribbonTabHeight, 32.0);
      });

      test('ribbonActionHeight is 56px', () {
        expect(AppDimensions.ribbonActionHeight, 56.0);
      });

      test('formulaBarHeight is 28px', () {
        expect(AppDimensions.formulaBarHeight, 28.0);
      });

      test('sheetTabStripHeight is 28px', () {
        expect(AppDimensions.sheetTabStripHeight, 28.0);
      });

      test('statusBarHeight is 22px', () {
        expect(AppDimensions.statusBarHeight, 22.0);
      });

      test('autofillHandleSize is 5px', () {
        expect(AppDimensions.autofillHandleSize, 5.0);
      });
    });

    group('AppTypography — Font Families', () {
      test('UI font family is Inter', () {
        expect(AppTypography.uiFontFamily, 'Inter');
      });

      test('Mono font family is JetBrains Mono', () {
        expect(AppTypography.monoFontFamily, 'JetBrains Mono');
      });

      test('cellText uses JetBrains Mono', () {
        expect(AppTypography.cellText.fontFamily, 'JetBrains Mono');
      });
    });

    group('AppTheme — Material Theme Smoke Tests', () {
      testWidgets('lightTheme builds without error', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('darkTheme builds without error', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SizedBox(),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });
  });
}
