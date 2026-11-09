import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _preferenceKey = 'devinsight_theme_mode';

  ThemeController({ThemeMode initialMode = ThemeMode.light})
    : _mode = initialMode;

  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_preferenceKey);
    return ThemeController(
      initialMode: savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _preferenceKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ThemeControllerScope>()
      ?.notifier;

  static ThemeController of(BuildContext context) =>
      maybeOf(context) ??
      (throw FlutterError(
        'ThemeControllerScope.of() called without a ThemeControllerScope.',
      ));
}
