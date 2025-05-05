import 'package:flutter/material.dart';

class AppState extends InheritedWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final ValueNotifier<Locale> localeNotifier;

  const AppState({
    super.key,
    required super.child,
    required this.themeModeNotifier,
    required this.localeNotifier,
  });

  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>();
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  void setLocale(Locale locale) {
    localeNotifier.value = locale;
  }

  @override
  bool updateShouldNotify(AppState oldWidget) {
    return themeModeNotifier != oldWidget.themeModeNotifier ||
        localeNotifier != oldWidget.localeNotifier;
  }
}
