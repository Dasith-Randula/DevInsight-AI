import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dashboard/core/theme/app_theme.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/shared/widgets/theme_toggle_button.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('theme preference persists and restores', () async {
    final controller = ThemeController();
    await controller.setMode(ThemeMode.dark);

    final restored = await ThemeController.load();

    expect(restored.mode, ThemeMode.dark);
  });

  testWidgets('theme toggle is accessible and switches modes', (tester) async {
    final controller = ThemeController();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: ThemeControllerScope(
          controller: controller,
          child: Scaffold(
            body: Center(child: ThemeToggleButton(controller: controller)),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(ThemeToggleButton)),
      matchesSemantics(
        label: 'Switch to Dark Mode',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pump();
    expect(controller.isDark, isTrue);
    expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);
    final toggleSize = tester.getSize(find.byType(ThemeToggleButton));
    expect(toggleSize.width, 56);
    expect(toggleSize.height, 28);
  });

  testWidgets('dark theme exposes the DevInsight semantic palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.appTheme.pageBackground,
            child: Text(
              'dark',
              style: TextStyle(color: context.appTheme.primaryText),
            ),
          ),
        ),
      ),
    );

    final theme = Theme.of(tester.element(find.text('dark')));
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.extension<AppThemeExtension>()?.pageBackground,
      const Color(0xFF080D19),
    );
    expect(
      theme.extension<AppThemeExtension>()?.primaryText,
      const Color(0xFFFFFFFF),
    );
    expect(
      theme.extension<AppThemeExtension>()?.secondaryText,
      const Color(0xFFB8D4F5),
    );
    expect(
      theme.extension<AppThemeExtension>()?.mutedText,
      const Color(0xFF91B7E6),
    );
  });
}
